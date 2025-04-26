//
// See LICENSE.txt for license information
//

import CNELwIP
import NIOCore

final class LwIPConnection {

  let wrapped: UnsafeMutablePointer<tcp_pcb>
  private let eventLoop: any EventLoop

  init(eventLoop: any EventLoop, wrapped: UnsafeMutablePointer<tcp_pcb>) {
    self.wrapped = wrapped
    self.eventLoop = eventLoop
  }

  func localAddress0() throws -> SocketAddress {
    var ipaddr = wrapped.pointee.local_ip
    guard let nullTerminatedUTF8 = ipaddr_ntoa(&ipaddr) else {
      throw SocketAddressError.unsupported
    }
    let ipAddress = String(cString: nullTerminatedUTF8)
    return try SocketAddress(ipAddress: ipAddress, port: Int(wrapped.pointee.local_port ?? 0))
  }

  func remoteAddress0() throws -> SocketAddress {
    var ipaddr = wrapped.pointee.remote_ip
    guard let nullTerminatedUTF8 = ipaddr_ntoa(&ipaddr) else {
      throw SocketAddressError.unsupported
    }
    let ipAddress = String(cString: nullTerminatedUTF8)
    return try SocketAddress(ipAddress: ipAddress, port: Int(wrapped.pointee.remote_port ?? 0))
  }

  func register0(promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    // passRetained object to make sure we hold connection during
    // `wrapped` is alive.
    tcp_arg(wrapped, Unmanaged.passRetained(self).toOpaque())
    tcp_err(wrapped) { opaquePtr, error in
      guard let opaquePtr else { return }
      // When we receive error we should release our connection
      // so .takeRetainedValue() is called, decreases the
      // reference count of the connection.
      Unmanaged<LwIPConnection>
        .fromOpaque(opaquePtr)
        .takeRetainedValue()
        .errorCaught0(error: LwIPError(code: error))
    }
    tcp_recv(wrapped) { opaquePtr, conn, data, error in
      guard error == ERR_OK else { return error }
      guard let opaquePtr, let conn else { return ERR_ARG }
      Unmanaged<LwIPConnection>
        .fromOpaque(opaquePtr)
        .takeUnretainedValue()
        .channelRead0(data)
      return ERR_OK
    }
    promise?.succeed()
  }

  func bind0(to address: SocketAddress, promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    promise?.succeed()
  }

  func becomeActive0(promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    promise?.succeed()
  }

  func channelRead0(_ data: UnsafeMutablePointer<pbuf>?) {
    eventLoop.assertInEventLoop()

    var byteBuffer = ByteBuffer()
    var bufferPtr = data
    while let data = bufferPtr {
      byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(data.pointee.tot_len)) {
        Int(pbuf_copy_partial(data, $0.baseAddress, data.pointee.len, 0))
      }
      bufferPtr = data.pointee.next
    }
    tcp_recved(wrapped, UInt16(byteBuffer.readableBytes))

    //      tcp_write(<#T##pcb: UnsafeMutablePointer<tcp_pcb>!##UnsafeMutablePointer<tcp_pcb>!#>, <#T##dataptr: UnsafeRawPointer!##UnsafeRawPointer!#>, <#T##len: u16_t##u16_t#>, <#T##apiflags: u8_t##u8_t#>)
    //      tcp_output(<#T##pcb: UnsafeMutablePointer<tcp_pcb>!##UnsafeMutablePointer<tcp_pcb>!#>)
  }

  func errorCaught0(error: any Error) {
    eventLoop.assertInEventLoop()

    // Do nothing
  }

  func flush0() {
    eventLoop.assertInEventLoop()
  }
}
