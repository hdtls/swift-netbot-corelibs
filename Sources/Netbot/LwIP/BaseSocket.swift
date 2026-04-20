// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import CNELwIP
import NEAddressProcessing
import NIOCore

@available(SwiftStdlib 5.3, *)
protocol BaseSocketProtocol {

  func close() throws

  func bind(to address: SocketAddress) throws

  func localAddress() throws -> SocketAddress

  func remoteAddress() throws -> SocketAddress
}

@available(SwiftStdlib 5.3, *)
class BaseSocket: BaseSocketProtocol {

  var descriptor: UnsafeMutablePointer<tcp_pcb>

  var isOpen = true

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
    guard self.isOpen else {
      return
    }

    let errno = err_to_errno(tcp_close(descriptor))
    if errno != 0 {
      throw IOError(errnoCode: errno, reason: "close")
    }
    tcp_arg(self.descriptor, nil)
    tcp_recv(self.descriptor, nil)
    tcp_sent(self.descriptor, nil)
    tcp_err(self.descriptor, nil)
    self.isOpen = false
  }
}

@available(SwiftStdlib 5.3, *)
extension BaseSocket: CustomStringConvertible {
  var description: String {
    "BaseSocket { fd=\(self.descriptor) }"
  }
}
