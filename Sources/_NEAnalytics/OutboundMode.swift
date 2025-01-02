//
// See LICENSE.txt for license information
//

@_exported public import Anlzr
@_exported public import Preference

#if canImport(Darwin)
  private import Foundation
#endif

extension OutboundMode: @retroactive RawRepresentable {

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

extension OutboundMode: @retroactive PreferenceRepresentable {}

extension OutboundMode {
  var localizedName: String {
    switch self {
    #if canImport(Darwin)
      case .direct:
        return String(localized: "Direct Outbound", comment: "")
      case .globalProxy:
        return String(localized: "Global Proxy", comment: "")
      case .ruleBased:
        return String(localized: "Rule-based Proxy", comment: "")
    #else
      case .direct:
        return "Direct Outbound"
      case .globalProxy:
        return "Global Proxy"
      case .ruleBased:
        return "Rule-based Proxy"
    #endif
    }
  }
}
