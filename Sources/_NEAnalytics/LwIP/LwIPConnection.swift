//
// See LICENSE.txt for license information
//

import Anlzr
import CNELwIP
import Dispatch
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore

final class LwIPConnection: @unchecked Sendable {

  var localAddress: Address? {
    if self.eventLoop.inEventLoop {
      return self._localAddress
    } else {
      return self._offEventLoopLock.withLock {
        self._localAddress
      }
    }
  }
  private var _localAddress: Address?

  var remoteAddress: Address? {
    if self.eventLoop.inEventLoop {
      return self._remoteAddress
    } else {
      return self._offEventLoopLock.withLock {
        self._remoteAddress
      }
    }
  }
  private var _remoteAddress: Address?

  private var socket: UnsafeMutablePointer<tcp_pcb>?
  private let eventLoop: any EventLoop

  private var recvBuffer: [(context: ContentContext, data: ByteBuffer?)]

  typealias Promise = @Sendable ((any Error)?) -> Void

  private var pendingWrites: [(data: ByteBuffer, promise: Promise?)] = []

  private let _offEventLoopLock = NIOLock()

  enum State: Equatable, Sendable {
    case setup
    case preparing
    case ready
    case failed(LwIPError)
    case cancelled
  }

  var state: State {
    if self.eventLoop.inEventLoop {
      return self._state
    } else {
      return self._offEventLoopLock.withLock {
        self._state
      }
    }
  }
  private var _state: State = .setup

  var queue: DispatchQueue? {
    if self.eventLoop.inEventLoop {
      return self._queue
    } else {
      return self._offEventLoopLock.withLock {
        self._queue
      }
    }
  }
  private var _queue: DispatchQueue?

  @preconcurrency final var stateUpdateHandler: (@Sendable (_ state: State) -> Void)? {
    get {
      if self.eventLoop.inEventLoop {
        return self._stateUpdateHandler
      } else {
        return self._offEventLoopLock.withLock {
          self._stateUpdateHandler
        }
      }
    }
    set {
      if self.eventLoop.inEventLoop {
        self._stateUpdateHandler = newValue
      } else {
        self.eventLoop.execute {
          self._stateUpdateHandler = newValue
        }
      }
    }
  }
  private var _stateUpdateHandler: (@Sendable (_ state: State) -> Void)?

  class ContentContext: @unchecked Sendable {

    let isFinal: Bool

    init(isFinal: Bool = false) {
      self.isFinal = isFinal
    }

    static let defaultMessage = ContentContext()

    static let finalMessage = ContentContext(isFinal: true)

    static let defaultStream = ContentContext()
  }

  init(socket: UnsafeMutablePointer<tcp_pcb>, parent: LwIPListener?, eventLoop: any EventLoop) {
    self.socket = socket
    self.recvBuffer = []
    self.eventLoop = eventLoop

    if let ipaddr = ipaddr_ntoa(&socket.pointee.local_ip) {
      let host = Address.Host(String(cString: ipaddr))
      let port = Address.Port(rawValue: socket.pointee.local_port)
      self._localAddress = .hostPort(host: host, port: port)
    }

    if let ipaddr = ipaddr_ntoa(&socket.pointee.remote_ip) {
      let host = Address.Host(String(cString: ipaddr))
      let port = Address.Port(rawValue: socket.pointee.remote_port)
      self._remoteAddress = .hostPort(host: host, port: port)
    }
  }

  deinit {

  }

  func start(queue: DispatchQueue) {
    let execute = {
      let opaquePtr = Unmanaged.passUnretained(self).toOpaque()
      tcp_arg(self.socket, opaquePtr)
      tcp_recv(self.socket) { contextPtr, connectionPtr, data, err in
        guard let contextPtr, let connectionPtr else {
          return ERR_ARG
        }

        let connection = Unmanaged<LwIPConnection>.fromOpaque(contextPtr).takeUnretainedValue()
        connection.eventLoop.assertInEventLoop()

        guard let data else {
          connection.recvBuffer.append((.finalMessage, nil))
          connection.close(mode: .input)
          return err
        }

        let totalLength = data.pointee.tot_len
        if totalLength > 0 {
          var byteBuffer = ByteBuffer()
          byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(totalLength)) {
            Int(pbuf_copy_partial(data, $0.baseAddress, totalLength, 0))
          }
          connection.recvBuffer.append((.defaultStream, byteBuffer))
        }
        pbuf_free(data)
        tcp_recved(connectionPtr, totalLength)
        return ERR_OK
      }
      tcp_sent(self.socket) { contextPtr, connectionPtr, _ in
        guard let contextPtr, let connectionPtr else {
          return ERR_ARG
        }

        let connection = Unmanaged<LwIPConnection>.fromOpaque(contextPtr).takeUnretainedValue()
        connection.eventLoop.assertInEventLoop()

        // check if we have write buffer here, and send it.
        guard !connection.pendingWrites.isEmpty else {
          return ERR_OK
        }
        let (data, promise) = connection.pendingWrites.removeFirst()
        connection.send0(content: data, completion: promise)
        return ERR_OK
      }
      tcp_err(self.socket) { contextPtr, error in
        guard let contextPtr else {
          return
        }
        let connection = Unmanaged<LwIPConnection>.fromOpaque(contextPtr).takeUnretainedValue()
        connection.eventLoop.assertInEventLoop()
        connection._state = .failed(LwIPError(code: err_to_errno(error)))
        connection.socket = nil
      }
    }

    if self.eventLoop.inEventLoop {
      self._queue = queue
      self._state = .preparing
      execute()
      self._state = .ready
    } else {
      self._offEventLoopLock.withLock {
        self._queue = queue
        self._state = .preparing
      }
      self.eventLoop.execute {
        execute()
        self._state = .ready
      }
    }
  }

  func send(
    content: ByteBuffer?,
    contentContext: ContentContext = .defaultMessage,
    isComplete: Bool = true,
    completion: @escaping Promise
  ) {
    let execute: @Sendable () -> Void = {
      if let data = content {
        self.pendingWrites.append((data, completion))
      }

      if self.pendingWrites.isEmpty {
        self.send0(content: nil, completion: completion)
      } else {
        let (data, promise) = self.pendingWrites.removeFirst()
        self.send0(content: data, completion: promise)
      }
    }

    if self.eventLoop.inEventLoop {
      execute()
    } else {
      self.eventLoop.execute(execute)
    }
  }

  private func send0(
    content: ByteBuffer?,
    contentContext: ContentContext = .defaultMessage,
    isComplete: Bool = true,
    completion: Promise?
  ) {
    self.eventLoop.assertInEventLoop()

    @Sendable func flush0(_ promise: (((any Error)?) -> Void)?) {
      self.eventLoop.assertInEventLoop()

      let errno = err_to_errno(tcp_output(self.socket))
      var error: (any Error)?
      if errno != 0 {
        error = LwIPError(code: errno)
      }
      self.queue?.async {
        promise?(error)
      }
    }

    // If no data to send, flush write buffer.
    guard var data = content else {
      flush0(completion)
      return
    }

    guard case .ready = self.state, let wrapped = self.socket else {
      self.queue?.async {
        completion?(ChannelError.ioOnClosedChannel)
      }
      return
    }

    // It's safe to convert Int to UInt16, because we have already checked
    // that the bigest value of min(_,_) result is clamping into 0xFFFF
    // witch is equal to UInt16.max.
    let length = UInt16(min(data.count, Int(min(wrapped.pointee.snd_buf, 0xFFFF))))

    let error = data.withUnsafeReadableBytes {
      err_to_errno(tcp_write(wrapped, $0.baseAddress, length, UInt8(TCP_WRITE_FLAG_COPY)))
    }
    if error == 0 {
      data.moveReaderIndex(to: Int(length))
    }

    // If data is still contains bytes, we should prepend write to write buffer
    // and waiting for next write loop.
    if !data.isEmpty {
      data.discardReadBytes()
      self.pendingWrites.insert((data, completion), at: 0)
      flush0(nil)
    } else {
      flush0(completion)
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

    let data = content

    self.queue?.async {
      completion(data, contentContext, true, nil)
    }
  }

  func cancel() {
    close()
  }

  internal func close(mode: CloseMode = .all) {
    let execute: @Sendable () -> Void = {
      switch mode {
      case .output:
        break
      case .input:
        tcp_recv(self.socket, tcp_recv_null)
        tcp_close(self.socket)
      case .all:
        tcp_arg(self.socket, nil)
        tcp_err(self.socket) { _, _ in }
        tcp_close(self.socket)
        self.socket = nil

        guard case .failed = self.state else {
          self._state = .cancelled
          return
        }
      }
    }

    if self.eventLoop.inEventLoop {
      execute()
    } else {
      self.eventLoop.execute(execute)
    }
  }
}
