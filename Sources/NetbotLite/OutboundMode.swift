//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

/// The network outbound mode.
@available(SwiftStdlib 5.3, *)
public enum OutboundMode: Sendable {

  /// Direct mode. In this mode all requests will be sent directly.
  case direct

  /// Global proxy mode. In this mode all requests will be forwarded to a proxy server.
  case globalProxy

  /// Rule-based model. In this mode all requests will be forwarded base on rule system.
  case ruleBased
}

@available(SwiftStdlib 5.3, *)
extension OutboundMode: RawRepresentable {

  public var rawValue: String {
    switch self {
    case .direct:
      return "direct-outbound"
    case .globalProxy:
      return "global-proxy"
    case .ruleBased:
      return "rule-based"
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "direct-outbound":
      self = .direct
    case "global-proxy":
      self = .globalProxy
    case "rule-based":
      self = .ruleBased
    default:
      return nil
    }
  }
}
