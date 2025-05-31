//
// See LICENSE.txt for license information
//

import Anlzr
import CNELwIP
import NEAddressProcessing
import NIOConcurrencyHelpers

@Lockable final class LwIPListener: @unchecked Sendable {

  public var localAddress: Address?

  public var remoteAddress: Address?

  private var wrapped: UnsafeMutablePointer<tcp_pcb>?

  var queue: DispatchQueue?

  @preconcurrency final var newConnectionHandler:
    (
      @Sendable (_ connection: LwIPConnection) -> Void
    )?

  public var port: UInt16? {
    if let port = localAddress?.port {
      return UInt16(port)
    }
    return nil
  }

  init() {
    let wrapped = tcp_new()
    self._wrapped = .init(wrapped)
    self._newConnectionHandler = .init(nil)
    self._queue = .init(nil)
    self._localAddress = .init(nil)
    self._remoteAddress = .init(nil)
  }

  func start(queue: DispatchQueue) {
    self.queue = queue

    let execute = {
      var ipaddr = ip_addr_any
      tcp_bind(self.wrapped, &ipaddr, 0)
      self.wrapped = tcp_listen_with_backlog(self.wrapped, UInt8(TCP_DEFAULT_LISTEN_BACKLOG))

      if let wrapped = self.wrapped {
        self._localAddress.withLock {
          guard let ipaddr = ipaddr_ntoa(&wrapped.pointee.local_ip) else {
            return
          }
          let port = wrapped.pointee.local_port
          $0 = .hostPort(host: .init(String(cString: ipaddr)), port: .init(rawValue: port))
        }
        self._remoteAddress.withLock {
          guard let ipaddr = ipaddr_ntoa(&wrapped.pointee.remote_ip) else {
            return
          }
          let port = wrapped.pointee.remote_port
          $0 = .hostPort(host: .init(String(cString: ipaddr)), port: .init(rawValue: port))
        }
      }

      let opaquePtr = Unmanaged.passUnretained(self).toOpaque()
      tcp_arg(self.wrapped, opaquePtr)
      tcp_accept(self.wrapped) { contextPtr, connection, error in
        guard let contextPtr, let connection else {
          return ERR_ARG
        }

        let listener = Unmanaged<LwIPListener>.fromOpaque(contextPtr).takeUnretainedValue()
        let newConnection = LwIPConnection(wrapped: connection)
        listener.queue?.async {
          listener.newConnectionHandler?(newConnection)
        }
        return ERR_OK
      }
    }

    if __workq.inQueue {
      execute()
    } else {
      __workq.sync(execute: execute)
    }
  }

  func cancel() {
    if __workq.inQueue {
      tcp_close(self.wrapped)
    } else {
      __workq.sync {
        tcp_close(self.wrapped)
      }
    }
  }
}
