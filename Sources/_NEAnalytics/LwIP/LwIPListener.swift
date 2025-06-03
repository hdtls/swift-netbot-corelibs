//
// See LICENSE.txt for license information
//

import Anlzr
import CNELwIP
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore

final class LwIPListener: @unchecked Sendable {

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

  private let socket: ServerSocket

  internal let eventLoop: any EventLoop
  private let group: any EventLoopGroup

  var closeFuture: EventLoopFuture<Void> {
    closePromise.futureResult
  }
  private var closePromise: EventLoopPromise<Void>

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

  @preconcurrency final var newConnectionHandler:
    (@Sendable (_ connection: LwIPConnection) -> Void)?
  {
    get {
      if self.eventLoop.inEventLoop {
        return self._newConnectionHandler
      } else {
        return self._offEventLoopLock.withLock {
          self._newConnectionHandler
        }
      }
    }
    set {
      if self.eventLoop.inEventLoop {
        self._newConnectionHandler = newValue
      } else {
        self.eventLoop.execute {
          self._newConnectionHandler = newValue
        }
      }
    }
  }
  private var _newConnectionHandler: (@Sendable (_ state: LwIPConnection) -> Void)?

  private let _offEventLoopLock = NIOLock()

  public var port: UInt16? {
    if let port = localAddress?.port {
      return UInt16(port)
    }
    return nil
  }

  init(eventLoop: any EventLoop, group: any EventLoopGroup) {
    self.socket = ServerSocket()
    self.eventLoop = eventLoop
    self.group = group
    self.closePromise = eventLoop.makePromise()
  }

  func start(queue: DispatchQueue) {
    let address = Address.hostPort(host: "0.0.0.0", port: .any)
    if self.eventLoop.inEventLoop {
      self._queue = queue
      self.bind0(to: address, promise: nil)
    } else {
      self._offEventLoopLock.withLock {
        self._queue = queue
      }
      self.eventLoop.execute {
        self.bind0(to: address, promise: nil)
      }
    }
  }

  func cancel() {
    if self.eventLoop.inEventLoop {
      self.close0(error: ChannelError.ioOnClosedChannel, mode: .all, promise: nil)
    } else {
      self.eventLoop.execute {
        self.close0(error: ChannelError.ioOnClosedChannel, mode: .all, promise: nil)
      }
    }
  }

  func localAddress0() throws -> Address {
    self.eventLoop.assertInEventLoop()
    guard self.socket.isOpen else {
      throw ChannelError.ioOnClosedChannel
    }
    return try self.socket.localAddress()
  }

  func remoteAddress0() throws -> Address {
    self.eventLoop.assertInEventLoop()
    guard self.socket.isOpen else {
      throw ChannelError.ioOnClosedChannel
    }
    return try self.socket.remoteAddress()
  }

  func bind0(to address: Address, promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()

    do {
      try self.socket.bind(to: address)
      try self.socket.listen()

      self._localAddress = try self.localAddress0()
      self._remoteAddress = try self.remoteAddress0()

      let opaquePtr = Unmanaged.passUnretained(self).toOpaque()
      tcp_arg(self.socket.descriptor, opaquePtr)
      tcp_accept(self.socket.descriptor) { contextPtr, connection, error in
        guard let contextPtr, let connection else {
          return ERR_ARG
        }

        let listener = Unmanaged<LwIPListener>.fromOpaque(contextPtr).takeUnretainedValue()
        let newConnection = LwIPConnection(
          socket: .init(socket: connection), parent: listener, eventLoop: listener.eventLoop
        )
        newConnection.start(queue: .global())
        listener.queue?.async {
          listener.newConnectionHandler?(newConnection)
        }
        return ERR_OK
      }
    } catch {
      promise?.fail(error)
    }
  }

  func close0(error: any Error, mode: CloseMode, promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()
    do {
      try self.socket.close()
      promise?.succeed()
    } catch {
      promise?.fail(error)
    }
    self.closePromise.succeed()
  }
}
