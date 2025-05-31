//
// See LICENSE.txt for license information
//

import Anlzr
import CNELwIP
import DequeModule
import Dispatch
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore

@Lockable final class LwIPConnection: @unchecked Sendable {

  var localAddress: Address?

  var remoteAddress: Address?

  private var wrapped: UnsafeMutablePointer<tcp_pcb>?

  private var recvBuffer: [(context: ContentContext, data: ByteBuffer?)]

  enum State: Equatable, Sendable {
    case setup
    case preparing
    case ready
    case failed(LwIPError)
    case cancelled
  }

  var state: State

  var queue: DispatchQueue?

  @preconcurrency final var stateUpdateHandler: (@Sendable (_ state: State) -> Void)?

  class ContentContext: @unchecked Sendable {

    let isFinal: Bool

    init(isFinal: Bool = false) {
      self.isFinal = isFinal
    }

    static let defaultMessage = ContentContext()

    static let finalMessage = ContentContext(isFinal: true)

    static let defaultStream = ContentContext()
  }

  init(wrapped: UnsafeMutablePointer<tcp_pcb>) {
    self._wrapped = .init(wrapped)
    self._recvBuffer = .init(.init())
    self._state = .init(.setup)
    self._stateUpdateHandler = .init(nil)
    self._queue = .init(nil)

    if let ipaddr = ipaddr_ntoa(&wrapped.pointee.local_ip) {
      let host = Address.Host(String(cString: ipaddr))
      let port = Address.Port(rawValue: wrapped.pointee.local_port)
      self._localAddress = .init(.hostPort(host: host, port: port))
    } else {
      self._localAddress = .init(nil)
    }

    if let ipaddr = ipaddr_ntoa(&wrapped.pointee.remote_ip) {
      let host = Address.Host(String(cString: ipaddr))
      let port = Address.Port(rawValue: wrapped.pointee.remote_port)
      self._remoteAddress = .init(.hostPort(host: host, port: port))
    } else {
      self._remoteAddress = .init(nil)
    }
  }

  deinit {

  }

  func start(queue: DispatchQueue) {
    self.queue = queue
    self.state = .preparing

    let execute = {
      let opaquePtr = Unmanaged.passUnretained(self).toOpaque()
      tcp_arg(self.wrapped, opaquePtr)
      tcp_recv(self.wrapped) { contextPtr, connectionPtr, data, err in
        guard let contextPtr, let connectionPtr else {
          return ERR_ARG
        }

        let connection = Unmanaged<LwIPConnection>.fromOpaque(contextPtr).takeUnretainedValue()

        guard let data else {
          connection._recvBuffer.withLock { $0.append((.finalMessage, nil)) }
          connection.close(mode: .input)
          return err
        }

        let totalLength = data.pointee.tot_len
        if totalLength > 0 {
          var byteBuffer = ByteBuffer()
          byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(totalLength)) {
            Int(pbuf_copy_partial(data, $0.baseAddress, totalLength, 0))
          }
          connection._recvBuffer.withLock {
            $0.append((.defaultStream, byteBuffer))
          }
        }
        pbuf_free(data)
        tcp_recved(connectionPtr, totalLength)
        return ERR_OK
      }
      tcp_err(self.wrapped) { contextPtr, error in
        guard let contextPtr else {
          return
        }
        //        let connection = Unmanaged<LwIPConnection>.fromOpaque(contextPtr).takeUnretainedValue()
        //        connection.state = .failed(LwIPError(code: error))
        //        connection.wrapped = nil
      }
    }

    if __workq.inQueue {
      execute()
    } else {
      __workq.sync(execute: execute)
    }

    self.state = .ready
  }

  func send(
    content: ByteBuffer?,
    contentContext: ContentContext = .defaultMessage,
    isComplete: Bool = true,
    completion: @escaping @Sendable ((any Error)?) -> Void
  ) {
    let execute = {
      guard case .ready = self.state, let wrapped = self.wrapped, let content else { return }

      guard UInt16(min(wrapped.pointee.snd_buf, 0xFFFF)) > content.readableBytes else {
        self.queue?.async {
          completion(LwIPError(code: ERR_MEM))
        }
        return
      }

      var error = content.withUnsafeReadableBytes { buffPtr in
        tcp_write(wrapped, buffPtr.baseAddress, UInt16(buffPtr.count), UInt8(TCP_WRITE_FLAG_COPY))
      }
      guard error == ERR_OK else {
        self.queue?.async {
          completion(LwIPError(code: error))
        }
        return
      }

      error = tcp_output(wrapped)
      guard error == ERR_OK else {
        self.queue?.async {
          completion(LwIPError(code: error))
        }
        return
      }
    }

    if __workq.inQueue {
      execute()
    } else {
      __workq.sync(execute: execute)
    }
  }

  func receive(
    minimumIncompleteLength: Int = 1,
    maximumLength: Int,
    completion: @escaping @Sendable (
      _ content: ByteBuffer?,
      _ contentContext: ContentContext?,
      _ isComplete: Bool,
      _ error: LwIPError?
    ) -> Void
  ) {
    var contentContext = ContentContext.defaultStream
    let content = self._recvBuffer.withLock {
      var content: ByteBuffer?

      while !$0.isEmpty, (content?.readableBytes ?? 0) < maximumLength {
        let (context, data) = $0.removeFirst()
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
              $0.insert((context, data), at: 0)
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

      return content
    }

    self.queue?.async {
      completion(content, contentContext, true, nil)
    }
  }

  func cancel() {
    close()
  }

  internal func close(mode: CloseMode = .all) {
    let execute = {
      switch mode {
      case .output:
        break
      case .input:
        break
      case .all:
        tcp_arg(self.wrapped, nil)
        tcp_recv(self.wrapped, tcp_recv_null)
        tcp_err(self.wrapped) { _, _ in }
        tcp_close(self.wrapped)
        self.wrapped = nil

        guard case .failed = self.state else {
          self.state = .cancelled
          return
        }
      }
    }

    if __workq.inQueue {
      execute()
    } else {
      __workq.sync(execute: execute)
    }
  }
}
