//
// See LICENSE.txt for license information
//

import CNELwIP
import NIOCore
import Logging

protocol BaseLwIPPCBProtocol {

  var descriptor: UnsafeMutablePointer<tcp_pcb> { get }

  var isOpen: Bool { get }

  func close() throws

  func bind(to address: SocketAddress) throws

  func localAddress() throws -> SocketAddress

  func remoteAddress() throws -> SocketAddress
}

protocol ServerLwIPPCBProtocol: BaseLwIPPCBProtocol {
  func listen(backlog: Int32) throws

  func accept(setNonBlocking: Bool) throws
}

protocol LwIPPCBProtocol: BaseLwIPPCBProtocol {
  func connect(to address: SocketAddress) throws -> Bool
}

class BaseLwIPPCB: BaseLwIPPCBProtocol {

  var descriptor: UnsafeMutablePointer<tcp_pcb>

  static func makeSocket(protocolFamily: NIOBSDSocket.ProtocolFamily) throws -> UnsafeMutablePointer<tcp_pcb> {
    switch protocolFamily {
    case .inet:
      tcp_new_ip_type(UInt8(IPADDR_TYPE_V4.rawValue))
    case .inet6:
      tcp_new_ip_type(UInt8(IPADDR_TYPE_V6.rawValue))
    default:
      throw IOError(errnoCode: EPERM, reason: "Operation not permitted.")
    }
  }

  init(socket descriptor: UnsafeMutablePointer<tcp_pcb>) {
    self.descriptor = descriptor
  }

  deinit {
    assert(!self.isOpen, "leak of open BaseLwIPPCB")
    Logger(label: "LwIP").debug("\(self) closed")
  }

  var isOpen: Bool {
    guard descriptor.pointee.state != CLOSED else {
      return false
    }
    return descriptor.pointee.state.rawValue < FIN_WAIT_1.rawValue
  }

  func localAddress() throws -> SocketAddress {
    var ipaddr = descriptor.pointee.local_ip
    guard let nullTerminatedUTF8 = ipaddr_ntoa(&ipaddr) else {
      throw SocketAddressError.unsupported
    }
    let ipAddress = String(cString: nullTerminatedUTF8)
    return try SocketAddress(ipAddress: ipAddress, port: Int(descriptor.pointee.local_port))
  }

  func remoteAddress() throws -> SocketAddress {
    var ipaddr = descriptor.pointee.remote_ip
    guard let nullTerminatedUTF8 = ipaddr_ntoa(&ipaddr) else {
      throw SocketAddressError.unsupported
    }
    let ipAddress = String(cString: nullTerminatedUTF8)
    return try SocketAddress(ipAddress: ipAddress, port: Int(descriptor.pointee.remote_port))
  }

  func bind(to address: SocketAddress) throws {
    var ipaddr = ip_addr_any
    switch address {
    case .v4(let v4):
      ipaddr.type = UInt8(IPADDR_TYPE_V4.rawValue)
      ipaddr.u_addr.ip4.addr = v4.address.sin_addr.s_addr
    case .v6(let v6):
      ipaddr.type = UInt8(IPADDR_TYPE_V6.rawValue)
      ipaddr.u_addr.ip6.addr = v6.address.sin6_addr.__u6_addr.__u6_addr32
    case .unixDomainSocket:
      throw SocketAddressError.unsupported
    }

    let rt = tcp_bind(descriptor, &ipaddr, UInt16(address.port ?? 0))
    switch rt {
    case ERR_VAL:
      throw ChannelError.inappropriateOperationForState
    case ERR_OK:
      break
    default:
      throw LwIPError(code: rt)
    }
  }

  func close() throws {
    // Ignore if PCB already closed or is closing.
    guard isOpen else {
      return
    }
    tcp_close(descriptor)
  }
}

class LwIPPCB: BaseLwIPPCB, LwIPPCBProtocol {

  init(protocolFamily: NIOBSDSocket.ProtocolFamily) throws {
    let sock = try BaseLwIPPCB.makeSocket(protocolFamily: protocolFamily)
    try super.init(socket: sock)
  }

  override init(socket descriptor: UnsafeMutablePointer<tcp_pcb>) {
    try super.init(socket: descriptor)
  }

  func connect(to address: SocketAddress) throws -> Bool {
    false
  }
}

class ServerLwIPPCB: BaseLwIPPCB, ServerLwIPPCBProtocol {

  init(protocolFamily: NIOBSDSocket.ProtocolFamily) throws {
    let sock = try BaseLwIPPCB.makeSocket(protocolFamily: protocolFamily)
    try super.init(socket: sock)
  }

  func listen(backlog: Int32 = TCP_DEFAULT_LISTEN_BACKLOG) throws {
    var errorCode = ERR_OK
    let newListener = tcp_listen_with_backlog_and_err(descriptor, UInt8(backlog), &errorCode)
    guard let newListener, errorCode == ERR_OK || errorCode == ERR_ALREADY else {
      throw LwIPError(code: errorCode)
    }
    descriptor = newListener
  }

  func accept(setNonBlocking: Bool) throws {

  }
}
