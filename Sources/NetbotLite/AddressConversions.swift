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

import NEAddressProcessing
import NIOCore

#if canImport(Network)
  import Network
#endif

@available(SwiftStdlib 5.3, *)
extension SocketAddress {

  public func asAddress() throws -> Address {
    switch self {
    case .v4:
      return .hostPort(host: .init(ipAddress!), port: .init(rawValue: UInt16(port ?? 0)))
    case .v6:
      return .hostPort(host: .init(ipAddress!), port: .init(rawValue: UInt16(port ?? 0)))
    case .unixDomainSocket:
      return .unix(path: pathname!)
    }
  }
}

@available(SwiftStdlib 5.3, *)
extension Address {

  public func asAddress() throws -> SocketAddress {
    switch self {
    case .hostPort(let host, let port):
      switch host {
      case .name(let string):
        return try SocketAddress.makeAddressResolvingHost(string, port: Int(port.rawValue))
      case .ipv4(let address):
        return try SocketAddress(ipAddress: "\(address)", port: Int(port.rawValue))
      case .ipv6(let address):
        return try SocketAddress(ipAddress: "\(address)", port: Int(port.rawValue))
      }
    case .unix(let path):
      return try SocketAddress(unixDomainSocketPath: path)
    case .url:
      throw AnalyzeError.operationUnsupported
    }
  }
}

#if canImport(Network)
  @available(SwiftStdlib 5.3, *)
  extension Address {
    public func asEndpoint() throws -> NWEndpoint {
      switch self {
      case .hostPort(let host, let port):
        let h: NWEndpoint.Host
        switch host {
        case .name(let name):
          h = .name(name, nil)
        case .ipv4(let v4):
          h = .ipv4(.init(v4.rawValue, nil)!)
        case .ipv6(let v6):
          h = .ipv6(.init(v6.rawValue, nil)!)
        }
        return .hostPort(host: h, port: .init(rawValue: port.rawValue)!)
      case .unix(let path):
        return .unix(path: path)
      case .url(let url):
        return .url(url)
      }
    }
  }

  @available(SwiftStdlib 5.3, *)
  extension NWEndpoint {
    public func asAddress() throws -> Address {
      switch self {
      case .hostPort(let host, let port):
        let h: Address.Host
        switch host {
        case .name(let name, _):
          h = .name(name)
        case .ipv4(let address):
          h = .ipv4(.init(address.rawValue)!)
        case .ipv6(let address):
          h = .ipv6(.init(address.rawValue)!)
        @unknown default:
          throw AnalyzeError.operationUnsupported
        }
        return .hostPort(host: h, port: .init(rawValue: port.rawValue))
      case .unix(let path):
        return .unix(path: path)
      case .url(let url):
        return .url(url)
      case .service, .opaque:
        throw AnalyzeError.operationUnsupported
      @unknown default:
        throw AnalyzeError.operationUnsupported
      }
    }
  }
#endif
