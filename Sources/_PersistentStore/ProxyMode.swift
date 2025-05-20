//
// See LICENSE.txt for license information
//

import Preference

/// An OptionSet for proxy mode.
public struct ProxyMode: OptionSet, RawRepresentable, Hashable, Sendable {

  public var rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Default proxy mode, enable both HTTP/HTTPS proxy.
  public static let webProxy = ProxyMode(rawValue: 1 << 0)

  /// By set proxy mode to `systemProxy`, we are modify system network proxies.
  public static let systemProxy = ProxyMode(rawValue: 1 << 1)

  /// Enable IP layer proxy.
  public static let enhanced = ProxyMode(rawValue: 1 << 2)
}

extension ProxyMode: PreferenceRepresentable {}
