//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CNELwIP
import NIOConcurrencyHelpers
import NIOCore

@available(SwiftStdlib 5.3, *)
final class LwIPConnection: BaseSocketChannel<Socket>, @unchecked Sendable {

  private var recvBuffer: [(context: ContentContext, data: ByteBuffer?)] = []

  private struct PendingStreamWrite {
    var data: ByteBuffer
    var promise: EventLoopPromise<Void>?
  }

  private var pendingWrites = MarkedCircularBuffer<PendingStreamWrite>(initialCapacity: 16)

  private var inputClosed = false
  private var outputClosed = false

  class ContentContext: @unchecked Sendable {

    let isFinal: Bool

    init(isFinal: Bool = false) {
      self.isFinal = isFinal
    }

    static let defaultMessage = ContentContext()

    static let finalMessage = ContentContext(isFinal: true)

    static let defaultStream = ContentContext()
  }

  final override var isWritable: Bool {
    // We can't compare with zero here, if there is no more memory
    // snd_buf could be set to 1, this cause infinite `flushNow`.
    self.socket.descriptor.pointee.snd_buf > 100
  }

  init(socket: Socket, parent: LwIPListener?, eventLoop: any EventLoop) {
    super.init(socket: socket, eventLoop: eventLoop)

    let opaquePtr = Unmanaged.passUnretained(self).toOpaque()
    tcp_arg(self.socket.descriptor, opaquePtr)
  }

  deinit {
    assert(inputClosed == true)
    assert(outputClosed == true)
    assert(pendingWrites.isEmpty)
  }

  override func close0(error: any Error, mode: CloseMode, promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()
    switch mode {
    case .output:
      if self.outputClosed {
        promise?.fail(ChannelError.outputClosed)
        return
      }
      if self.inputClosed {
        self.close0(error: error, mode: .all, promise: promise)
        return
      }

      tcp_sent(self.socket.descriptor, nil)
      while let pendingWrite = self.pendingWrites.popFirst() {
        pendingWrite.promise?.fail(error)
      }
      self.outputClosed = true
      self.pipeline.fireUserInboundEventTriggered(ChannelEvent.outputClosed)
    case .input:
      if self.inputClosed {
        promise?.fail(ChannelError.inputClosed)
        return
      }
      if self.outputClosed {
        self.close0(error: error, mode: .all, promise: promise)
        return
      }

      tcp_recv(self.socket.descriptor, nil)
      self.readPending = false
      self.inputClosed = true
      self.pipeline.fireUserInboundEventTriggered(ChannelEvent.inputClosed)
    case .all:
      self.inputClosed = true
      self.outputClosed = true
      while let pendingWrite = self.pendingWrites.popFirst() {
        pendingWrite.promise?.fail(error)
      }
      super.close0(error: error, mode: mode, promise: promise)
    }
  }

  func receive(
    minimumIncompleteLength: Int = 1,
    maximumLength: Int,
    completion:
      @escaping @Sendable (
        _ content: ByteBuffer?,
        _ contentContext: ContentContext?,
        _ isComplete: Bool,
        _ error: (any Error)?
      ) -> Void
  ) {
    let execute: @Sendable () -> (ByteBuffer?, ContentContext) = {
      var contentContext = ContentContext.defaultStream
      var content: ByteBuffer?

      while !self.recvBuffer.isEmpty, (content?.readableBytes ?? 0) < maximumLength {
        let (context, data) = self.recvBuffer.removeFirst()
        // If total bytes of `content` and current `data` is less then or equal to `maximumLength`
        // we should write hole data into `content`, otherwise read part of data into content.
        if (content?.readableBytes ?? 0) + (data?.readableBytes ?? 0) <= maximumLength {
          if let data {
            content.setOrWriteImmutableBuffer(data)
          }

          // If this is the final message, break the receive loop.
          if context === LwIPConnection.ContentContext.finalMessage {
            contentContext = .finalMessage
            break
          }
        } else {
          // Why we need read operations if no data in `recvBuffer`'s current data.
          if var data {
            let bytesToRead = maximumLength - (content?.readableBytes ?? 0)
            content.setOrWriteImmutableBuffer(data.readSlice(length: bytesToRead)!)
            data.discardReadBytes()

            if !data.isEmpty {
              // Prepend the left data to recvBuffer, so that we can read it in another loop.
              self.recvBuffer.insert((context, data), at: 0)
            } else {

              // If no data left, we should check whether we should break read loop.
              if context === LwIPConnection.ContentContext.finalMessage {
                break
              }
            }
          } else {
            // If current data is nil and the context is final message, we should break the loop.
            if context === LwIPConnection.ContentContext.finalMessage {
              contentContext = .finalMessage
              break
            }
          }
        }
      }

      return (content, contentContext)
    }

    if self.eventLoop.inEventLoop {
      let (data, contentContext) = execute()
      completion(data, contentContext, true, nil)
    } else {
      self.eventLoop.execute {
        let (data, contentContext) = execute()
        completion(data, contentContext, true, nil)
      }
    }
  }

  final override func register0(promise: EventLoopPromise<Void>?) {
    guard self.isOpen else {
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    tcp_recv(self.socket.descriptor) { contextPtr, connectionPtr, data, err in
      guard let contextPtr else {
        return ERR_ABRT
      }

      let connection = Unmanaged<LwIPConnection>.fromOpaque(contextPtr).takeUnretainedValue()
      connection.eventLoop.assertInEventLoop()

      guard let data else {
        connection.recvBuffer.append((.finalMessage, nil))
        connection.pipeline.fireChannelReadComplete()
        connection.close(mode: .input, promise: nil)
        return err
      }

      let totalLength = data.pointee.tot_len
      if totalLength > 0 {
        var byteBuffer = connection.allocator.buffer(capacity: Int(totalLength))
        byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(totalLength)) {
          Int(pbuf_copy_partial(data, $0.baseAddress, totalLength, 0))
        }
        connection.recvBuffer.append((.defaultStream, byteBuffer))
        connection.pipeline.fireChannelRead(byteBuffer)
        connection.pipeline.fireChannelReadComplete()
      }
      pbuf_free(data)
      tcp_recved(connectionPtr, totalLength)
      return ERR_OK
    }
    tcp_sent(self.socket.descriptor) { contextPtr, connectionPtr, _ in
      guard let contextPtr else {
        return ERR_ABRT
      }

      let connection = Unmanaged<LwIPConnection>.fromOpaque(contextPtr).takeUnretainedValue()
      connection.eventLoop.assertInEventLoop()

      // check if we have write buffer here, and send it.
      guard !connection.pendingWrites.isEmpty else {
        return ERR_OK
      }
      connection.flushNow()
      connection.pipeline.fireChannelWritabilityChanged()
      return ERR_OK
    }
    tcp_err(self.socket.descriptor) { contextPtr, errno in
      guard let contextPtr else {
        return
      }
      let connection = Unmanaged<LwIPConnection>.fromOpaque(contextPtr).takeUnretainedValue()
      connection.eventLoop.assertInEventLoop()
      let error = IOError(errnoCode: err_to_errno(errno), reason: "tcp_err")
      switch errno {
      case ERR_CLSD:
        connection.socket.isOpen = false
        connection.close(promise: nil)
      default:
        connection.socket.isOpen = false
        connection.pipeline.fireErrorCaught(error)
        connection.close(promise: nil)
      }
    }

    promise?.succeed()
  }

  final override func read0() {
    if self.inputClosed {
      return
    }
    super.read0()
  }

  final override func readFromSocket() throws -> ReadResult {
    return .some
  }

  @discardableResult
  final override func readIfNeeded0() -> Bool {
    if self.inputClosed {
      return false
    }
    return super.readIfNeeded0()
  }

  final override func writeToSocket() throws {
    while var pendingWrite = self.pendingWrites.first {
      // It's safe to convert Int to UInt16, because we have already checked
      // that the bigest value of min(_,_) result is clamping into 0xFFFF
      // witch is equal to UInt16.max.
      let writableBytes = UInt16(
        min(pendingWrite.data.count, Int(min(self.socket.descriptor.pointee.snd_buf, 0xFFFF)))
      )

      var flags = TCP_WRITE_FLAG_COPY
      if writableBytes < pendingWrite.data.count {
        flags |= TCP_WRITE_FLAG_MORE
      }

      do {
        try pendingWrite.data
          .getSlice(at: pendingWrite.data.startIndex, length: Int(writableBytes))?
          .withUnsafeReadableBytes {
            try self.socket.write(pointer: $0, flags: flags)
          }

        if self.pendingWrites.isMarked(index: self.pendingWrites.startIndex) {
          let errno = err_to_errno(tcp_output(self.socket.descriptor))
          if errno != 0 {
            throw IOError(errnoCode: errno, reason: #function)
          }
        }

        guard pendingWrite.data.readableBytes > writableBytes else {
          _ = self.pendingWrites.removeFirst()
          pendingWrite.promise?.succeed()
          continue
        }

        pendingWrite.data.moveReaderIndex(forwardBy: Int(writableBytes))
        pendingWrite.data.discardReadBytes()
        self.pendingWrites[self.pendingWrites.startIndex] = pendingWrite

        // Writable buffer is full, try to flush enqueued tcp writes and break write loop.
        let errno = err_to_errno(tcp_output(self.socket.descriptor))
        if errno != 0 {
          throw IOError(errnoCode: errno, reason: #function)
        }
        break
      } catch {
        pendingWrite.promise?.fail(error)
        throw error
      }
    }
  }

  final override func hasFlushedPendingWrites() -> Bool {
    self.pendingWrites.hasMark
  }

  final override func markFlushPoint() {
    self.pendingWrites.mark()
  }

  final override func bufferPendingWrite(data: NIOAny, promise: EventLoopPromise<Void>?) {
    guard !self.outputClosed else {
      promise?.fail(ChannelError.outputClosed)
      return
    }

    let data = self.unwrapData(data, as: ByteBuffer.self)

    self.pendingWrites.append(.init(data: data, promise: promise))
  }
}
