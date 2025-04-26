//
// See LICENSE.txt for license information
//

import CNELwIP
import NIOCore

final class LwIPListener {

  private var listener: UnsafeMutablePointer<tcp_pcb>
  private let eventLoop: any EventLoop

  init(eventLoop: any EventLoop) {
    self.listener = tcp_new()
    self.eventLoop = eventLoop
  }

  deinit {
    tcp_free(listener)
  }

  func localAddress0() throws -> SocketAddress {
    var ipaddr = listener.pointee.local_ip
    guard let nullTerminatedUTF8 = ipaddr_ntoa(&ipaddr) else {
      throw SocketAddressError.unsupported
    }
    let ipAddress = String(cString: nullTerminatedUTF8)
    return try SocketAddress(ipAddress: ipAddress, port: Int(listener.pointee.local_port ?? 0))
  }

  func remoteAddress0() throws -> SocketAddress {
    var ipaddr = listener.pointee.remote_ip
    guard let nullTerminatedUTF8 = ipaddr_ntoa(&ipaddr) else {
      throw SocketAddressError.unsupported
    }
    let ipAddress = String(cString: nullTerminatedUTF8)
    return try SocketAddress(ipAddress: ipAddress, port: Int(listener.pointee.remote_port ?? 0))
  }

  func register0(promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    tcp_arg(listener, Unmanaged.passUnretained(self).toOpaque())
    tcp_accept(listener) { contextPtr, connection, error in
      guard error == ERR_OK else { return error }
      guard let contextPtr, let connection else { return ERR_ARG }
      let listener = Unmanaged<LwIPListener>.fromOpaque(contextPtr).takeUnretainedValue()
      let eventLoop = listener.eventLoop
      let newConnection = LwIPConnection(eventLoop: eventLoop, wrapped: connection)
      listener.channelRead0(newConnection)
      return error
    }
    promise?.succeed()
  }

  private func listen(backlog: Int32) throws {
    eventLoop.assertInEventLoop()

    let newListener = tcp_listen_with_backlog(listener, UInt8(backlog))
    guard let newListener else {
      tcp_close(listener)
      return
    }
    listener = newListener
  }

  func bind0(to address: SocketAddress, promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    var addr = ip_addr_any
    guard ERR_OK == tcp_bind(listener, &addr, UInt16(address.port ?? 0)) else {
      promise?.fail(ChannelError.inappropriateOperationForState)
      return
    }
    do {
      try listen(backlog: TCP_DEFAULT_LISTEN_BACKLOG)
      register0(promise: promise)
    } catch {
      promise?.fail(error)
    }
  }

  func becomeActive0(promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    promise?.succeed()
  }

  func channelRead0(_ data: LwIPConnection) {
    eventLoop.assertInEventLoop()

    let ch = data
    tcp_backlog_accepted(data.wrapped)
    ch.register0(promise: nil)
    ch.becomeActive0(promise: nil)
  }

  func errorCaught0(error: any Error) {
    eventLoop.assertInEventLoop()

    // Do nothing
  }
}
