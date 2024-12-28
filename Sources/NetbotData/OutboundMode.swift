//
// See LICENSE.txt for license information
//

public import Preference

#if canImport(FoundationEssentials)
  private import _FoundationEssentials
#else
  private import Foundation
#endif

/// The network outbound mode.
public enum OutboundMode: String, RawRepresentable, Sendable {

  /// Direct mode. In this mode all requests will be sent directly.
  case direct = "direct-outbound"

  /// Global proxy mode. In this mode all requests will be forwarded to a proxy server.
  case globalProxy = "global-proxy"

  /// Rule-based model. In this mode all requests will be forwarded base on rule system.
  case ruleBased = "rule-based"
}

extension OutboundMode: PreferenceRepresentable {}

extension OutboundMode {
  public var localizedName: String {
    switch self {
    case .direct:
      return String(localized: "Direct Outbound", comment: "")
    case .globalProxy:
      return String(localized: "Global Proxy", comment: "")
    case .ruleBased:
      return String(localized: "Rule-based Proxy", comment: "")
    }
  }

  public var localizedDescription: String {
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
  }
}

extension OutboundMode: CaseIterable {
  public static var allCases: [OutboundMode] {
    [.direct, .globalProxy, .ruleBased]
  }
}
