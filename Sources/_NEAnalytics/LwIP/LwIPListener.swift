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

  private var wrapped: UnsafeMutablePointer<tcp_pcb>?

  private let eventLoop: any EventLoop
  private let group: any EventLoopGroup

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
    self.wrapped = tcp_new()
    self.eventLoop = eventLoop
    self.group = group
  }

  func start(queue: DispatchQueue) {
    let execute: @Sendable () -> Void = {
      var ipaddr = ip_addr_any
      tcp_bind(self.wrapped, &ipaddr, 0)
      self.wrapped = tcp_listen_with_backlog(self.wrapped, UInt8(TCP_DEFAULT_LISTEN_BACKLOG))

      if let wrapped = self.wrapped {
        if let ipaddr = ipaddr_ntoa(&wrapped.pointee.local_ip) {
          let port = wrapped.pointee.local_port
          self._localAddress =
            .hostPort(host: .init(String(cString: ipaddr)), port: .init(rawValue: port))
        }

        if let ipaddr = ipaddr_ntoa(&wrapped.pointee.remote_ip) {
          let port = wrapped.pointee.remote_port
          self._remoteAddress =
            .hostPort(host: .init(String(cString: ipaddr)), port: .init(rawValue: port))
        }
      }

      let opaquePtr = Unmanaged.passUnretained(self).toOpaque()
      tcp_arg(self.wrapped, opaquePtr)
      tcp_accept(self.wrapped) { contextPtr, connection, error in
        guard let contextPtr, let connection else {
          return ERR_ARG
        }

        let listener = Unmanaged<LwIPListener>.fromOpaque(contextPtr).takeUnretainedValue()
        let newConnection = LwIPConnection(
          socket: connection, parent: listener, eventLoop: listener.eventLoop
        )
        newConnection.start(queue: .global())
        listener.queue?.async {
          listener.newConnectionHandler?(newConnection)
        }
        return ERR_OK
      }
    }

    if self.eventLoop.inEventLoop {
      self._queue = queue
      execute()
    } else {
      self._offEventLoopLock.withLock {
        self._queue = queue
      }
      self.eventLoop.execute(execute)
    }
  }

  func cancel() {
    if self.eventLoop.inEventLoop {
      tcp_close(self.wrapped)
    } else {
      self.eventLoop.execute {
        tcp_close(self.wrapped)
      }
    }
  }
}
