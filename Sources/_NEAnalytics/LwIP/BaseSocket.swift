//
// See LICENSE.txt for license information
//

import CNELwIP
import NEAddressProcessing
import NIOCore

protocol BaseSocketProtocol {

  func close() throws

  func bind(to address: SocketAddress) throws

  func localAddress() throws -> SocketAddress

  func remoteAddress() throws -> SocketAddress
}

class BaseSocket: BaseSocketProtocol {

  var descriptor: UnsafeMutablePointer<tcp_pcb>

  var isOpen: Bool {
    switch descriptor.pointee.state {
    case CLOSED, FIN_WAIT_1, FIN_WAIT_2, CLOSE_WAIT, CLOSING, LAST_ACK, TIME_WAIT:
      return false
    case LISTEN, SYN_SENT, SYN_RCVD, ESTABLISHED:
      return true
    default:
      return true
    }
  }

  init(socket descriptor: UnsafeMutablePointer<tcp_pcb>) {
    self.descriptor = descriptor
  }

  deinit {
    assert(!self.isOpen, "leak of open BaseSocket")
  }

  /// Returns the local bound `SocketAddress` of the socket.
  ///
  /// - Returns: The local bound address.
  /// - Throws: An `IOError` if the retrieval of the address failed.
  final func localAddress() throws -> SocketAddress {
    let port = self.descriptor.pointee.local_port
    let host = try LwIP.inet_ntoa(self.descriptor.pointee.local_ip)
    return try SocketAddress(ipAddress: host, port: Int(port))
  }

  /// Returns the connected `SocketAddress` of the socket.
  ///
  /// - Returns: The connected address.
  /// - Throws: An `IOError` if the retrieval of the address failed.
  final func remoteAddress() throws -> SocketAddress {
    let port = self.descriptor.pointee.remote_port
    let host = try LwIP.inet_ntoa(self.descriptor.pointee.remote_ip)
    return try SocketAddress(ipAddress: host, port: Int(port))
  }

  func bind(to address: SocketAddress) throws {
    guard case .v4 = address, let host = address.ipAddress, let port = address.port else {
      throw IOError(errnoCode: EADDRNOTAVAIL, reason: #function)
    }

    var ipaddr: ip_addr_t = ip_addr_any
    try LwIP.inet_aton(host, &ipaddr)
    let errno = err_to_errno(tcp_bind(descriptor, &ipaddr, UInt16(port)))
    if errno != 0 {
      throw IOError(errnoCode: errno, reason: #function)
    }
  }

  func close() throws {
    let errno = err_to_errno(tcp_close(descriptor))
    if errno != 0 {
      throw IOError(errnoCode: errno, reason: "close")
    }
  }

  final func takeDescriptorOwnership() throws {
    guard let descriptor = tcp_new() else {
      throw IOError(errnoCode: ENOBUFS, reason: "takeDescriptorOwnership")
    }
    descriptor.pointee.state = CLOSED
    descriptor.pointee.local_port = 0
    self.descriptor = descriptor
  }
}

extension BaseSocket: CustomStringConvertible {
  var description: String {
    "BaseSocket { fd=\(self.descriptor) }"
  }
}
