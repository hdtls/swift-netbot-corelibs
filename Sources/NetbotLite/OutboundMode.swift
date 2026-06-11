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

/// The network outbound mode.
@available(SwiftStdlib 6.0, *)
public enum OutboundMode: Sendable {

  /// Direct mode. In this mode all requests will be sent directly.
  case direct

  /// Global proxy mode. In this mode all requests will be forwarded to a proxy server.
  case globalProxy

  /// Rule-based model. In this mode all requests will be forwarded base on rule system.
  case ruleBased
}

@available(SwiftStdlib 6.0, *)
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
