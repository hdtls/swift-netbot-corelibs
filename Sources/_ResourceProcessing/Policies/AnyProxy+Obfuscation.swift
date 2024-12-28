//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  private import _FoundationEssentials
#else
  private import Foundation
#endif

extension AnyProxy {

  /// Data obfuscation settings.
  public struct Obfuscation: Codable, Hashable, Sendable {

    /// Stream obfuscating strategy.
    public struct Strategy: OptionSet, CaseIterable, Codable, Hashable, Sendable {
      public var rawValue: Int

      public init(rawValue: Int) {
        self.rawValue = rawValue
      }

      /// Obfuscate stream with HTTP protocol.
      public static let http: Strategy = .init(rawValue: 1)

      /// Obfuscate stream with TLS protocol.
      public static let tls: Strategy = .init(rawValue: 1 << 1)

      public static var allCases: [AnyProxy.Obfuscation.Strategy] {
        [.http, .tls]
      }

      public var localizedName: String {
        switch self {
        case .http:
          return String(localized: "HTTP")
        case .tls:
          return String(localized: "TLS")
        default:
          assertionFailure("Unknown obfuscation strategy \(self)")
          return ""
        }
      }
    }

    /// A boolean value determine whether this settings should be enabled.
    public var isEnabled = false

    /// The strategy of this obfuscate settings.
    public var strategy: Strategy = .http

    /// The hostname of this obfuscating will use.
    public var hostname: String = ""

    /// Create instance of `Obfuscation` with specified `isEnable` `strategy` and `hostname`.
    public init(isEnabled: Bool = false, strategy: Strategy = .http, hostname: String = "") {
      self.isEnabled = isEnabled
      self.strategy = strategy
      self.hostname = hostname
    }
  }
}
