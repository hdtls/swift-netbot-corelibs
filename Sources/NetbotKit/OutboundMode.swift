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

import Preference

#if canImport(Darwin)
  import Foundation
#endif

/// The network outbound mode.
@available(SwiftStdlib 5.3, *)
public enum OutboundMode: String, RawRepresentable, Sendable {

  /// Direct mode. In this mode all requests will be sent directly.
  case direct = "direct-outbound"

  /// Global proxy mode. In this mode all requests will be forwarded to a proxy server.
  case globalProxy = "global-proxy"

  /// Rule-based model. In this mode all requests will be forwarded base on rule system.
  case ruleBased = "rule-based"
}

@available(SwiftStdlib 5.3, *)
extension OutboundMode: PreferenceRepresentable {}

@available(SwiftStdlib 5.3, *)
extension OutboundMode {

  public var localizedName: String {
    #if canImport(Darwin)
      if #available(SwiftStdlib 5.5, *) {
        switch self {
        case .direct: return String(localized: "Direct Outbound", comment: "")
        case .globalProxy: return String(localized: "Global Proxy", comment: "")
        case .ruleBased: return String(localized: "Rule-based Proxy", comment: "")
        }
      } else {
        switch self {
        case .direct: return NSLocalizedString("Direct Outbound", comment: "")
        case .globalProxy: return NSLocalizedString("Global Proxy", comment: "")
        case .ruleBased: return NSLocalizedString("Rule-based Proxy", comment: "")
        }
      }
    #else
      switch self {
      case .direct:
        return "Direct Outbound"
      case .globalProxy:
        return "Global Proxy"
      case .ruleBased:
        return "Rule-based Proxy"
      }
    #endif
  }

  public var localizedDescription: String {
    #if canImport(Darwin)
      if #available(SwiftStdlib 5.5, *) {
        switch self {
        case .direct:
          return String(
            localized: "All requests will be sent directly",
            comment: "Direct outbound mode help message"
          )
        case .globalProxy:
          return String(
            localized: "All requests will be forwarded to a proxy server",
            comment: "Proxy outbound mode help message"
          )
        case .ruleBased:
          return String(
            localized: "All requests will be forwarded base on rule system",
            comment: "Rule-Based outbound mode help message"
          )
        }
      } else {
        switch self {
        case .direct:
          return NSLocalizedString(
            "All requests will be sent directly", comment: "Direct outbound mode help message")
        case .globalProxy:
          return NSLocalizedString(
            "All requests will be forwarded to a proxy server",
            comment: "Proxy outbound mode help message")
        case .ruleBased:
          return NSLocalizedString(
            "All requests will be forwarded base on rule system",
            comment: "Rule-Based outbound mode help message")
        }
      }
    #else
      switch self {
      case .direct: return "All requests will be sent directly"
      case .globalProxy: return "All requests will be forwarded to a proxy server"
      case .ruleBased: return "All requests will be forwarded base on rule system"
      }
    #endif
  }
}

@available(SwiftStdlib 5.3, *)
extension OutboundMode: CaseIterable {
  public static var allCases: [OutboundMode] {
    [.direct, .globalProxy, .ruleBased]
  }
}
