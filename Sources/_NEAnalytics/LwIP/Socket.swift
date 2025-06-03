//
// See LICENSE.txt for license information
//

import CNELwIP
import NEAddressProcessing
import NIOCore

class BaseSocket {

  var descriptor: UnsafeMutablePointer<tcp_pcb>
  public var isOpen: Bool {
    true
  }

  init(socket descriptor: UnsafeMutablePointer<tcp_pcb>) {
    self.descriptor = descriptor
  }

  /// Returns the local bound `Address` of the socket.
  ///
  /// - Returns: The local bound address.
  /// - Throws: An `IOError` if the retrieval of the address failed.
  func localAddress() throws -> Address {
    guard let ipaddr = ipaddr_ntoa(&descriptor.pointee.local_ip) else {
      throw IOError(errnoCode: EINVAL, reason: "inet_ntoa")
    }
    let port = descriptor.pointee.local_port
    let host = String(cString: ipaddr)
    return .hostPort(host: .init(host), port: .init(rawValue: port))
  }

  /// Returns the connected `Address` of the socket.
  ///
  /// - Returns: The connected address.
  /// - Throws: An `IOError` if the retrieval of the address failed.
  func remoteAddress() throws -> Address {
    guard let ipaddr = ipaddr_ntoa(&descriptor.pointee.remote_ip) else {
      throw IOError(errnoCode: EINVAL, reason: "inet_ntoa")
    }
    let port = descriptor.pointee.remote_port
    let host = String(cString: ipaddr)
    return .hostPort(host: .init(host), port: .init(rawValue: port))
  }

  func bind(to address: Address) throws {
    guard case .hostPort(let host, let port) = address else {
      throw IOError(errnoCode: EADDRNOTAVAIL, reason: "tcp_bind")
    }

    try host.debugDescription.withCString {
      var ipaddr: ip_addr_t = ip_addr_any
      guard ipaddr_aton($0, &ipaddr) == 1 else {
        throw IOError(errnoCode: EADDRNOTAVAIL, reason: "tcp_bind")
      }
      let errno = err_to_errno(tcp_bind(descriptor, &ipaddr, port.rawValue))
      if errno != 0 {
        throw IOError(errnoCode: errno, reason: "tcp_bind")
      }
    }
  }

  func close() throws {
    let errno = err_to_errno(tcp_close(descriptor))
    if errno != 0 {
      throw IOError(errnoCode: errno, reason: "tcp_close")
    }
  }
}

extension BaseSocket: CustomStringConvertible {
  var description: String {
    "BaseSocket { fd=\(self.descriptor) }"
  }
}

class ServerSocket: BaseSocket {

  convenience init() {
    self.init(socket: tcp_new())
  }

  func listen(backlog: UInt8 = 128) throws {
    guard self.isOpen else {
      throw IOError(errnoCode: EBADF, reason: "file descriptor already closed!")
    }
    self.descriptor = tcp_listen_with_backlog(descriptor, backlog)
  }
}

class Socket: BaseSocket {

  func write(pointer: UnsafeRawBufferPointer, flags: Int32) throws {
    var rt = tcp_write(self.descriptor, pointer.baseAddress, u16_t(pointer.count), UInt8(flags))
    guard rt == ERR_OK else {
      throw IOError(errnoCode: err_to_errno(rt), reason: "tcp_write")
    }

    rt = tcp_output(self.descriptor)
    guard rt == ERR_OK else {
      throw IOError(errnoCode: err_to_errno(rt), reason: "tcp_output")
    }
  }
}
