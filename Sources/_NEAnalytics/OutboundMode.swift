//
// See LICENSE.txt for license information
//

import Anlzr
import Preference

#if canImport(Darwin)
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
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

@available(SwiftStdlib 5.3, *)
extension OutboundMode: @retroactive PreferenceRepresentable {}

@available(SwiftStdlib 5.3, *)
extension OutboundMode {
  var localizedName: String {
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
}
