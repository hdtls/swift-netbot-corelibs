// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import NEAddressProcessing
import NIOCore

@available(SwiftStdlib 6.0, *)
extension Address {

  /// Convert Address to SocketAddress.
  package func asAddress() throws -> SocketAddress {
    switch self {
    case .hostPort(let host, let port):
      switch host {
      case .name:
        throw SocketAddressError.unsupported
      case .ipv4(let address):
        return try SocketAddress(ipAddress: "\(address)", port: Int(port.rawValue))
      case .ipv6(let address):
        return try SocketAddress(ipAddress: "\(address)", port: Int(port.rawValue))
      }
    case .unix(let path):
      return try SocketAddress(unixDomainSocketPath: path)
    case .url:
      throw SocketAddressError.unsupported
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension SocketAddress {

  /// Convert SocketAddress to Address.
  package func asAddress() throws -> Address {
    switch self {
    case .v4:
      return .hostPort(host: .init(ipAddress!), port: .init(rawValue: UInt16(port!)))
    case .v6:
      return .hostPort(host: .init(ipAddress!), port: .init(rawValue: UInt16(port!)))
    case .unixDomainSocket:
      return .unix(path: pathname!)
    }
  }
}
