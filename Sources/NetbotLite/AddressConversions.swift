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

#if canImport(Network)
  import NEAddressProcessing
  import Network

  @available(SwiftStdlib 6.0, *)
  extension Address {
    package func asEndpoint() throws -> NWEndpoint {
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

  @available(SwiftStdlib 6.0, *)
  extension NWEndpoint {
    package func asAddress() throws -> Address {
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
