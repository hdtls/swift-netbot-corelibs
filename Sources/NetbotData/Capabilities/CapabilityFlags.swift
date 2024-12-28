//
// See LICENSE.txt for license information
//

@_exported public import Preference

#if canImport(FoundationEssentials)
  private import _FoundationEssentials
#else
  private import Foundation
#endif

/// An OptionSet for all supported capabilities.
public struct CapabilityFlags: OptionSet, Hashable, Sendable {

  public typealias RawValue = Int

  public var rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// HTTP body capture.
  public static let httpCapture = CapabilityFlags(rawValue: 1)

  /// HTTPS decryption(MitM).
  public static let httpsDecryption = CapabilityFlags(rawValue: 1 << 1)

  public static let rewrite = CapabilityFlags(rawValue: 1 << 2)

  public static let scripting = CapabilityFlags(rawValue: 1 << 3)
}

extension CapabilityFlags: PreferenceRepresentable {}

extension CapabilityFlags {
  public var localizedName: String {
    switch self {
    case .httpCapture:
      return String(
        localized: "Enable HTTP Capture", comment: "CapabilityFlags for HTTP Capture")
    case .httpsDecryption:
      return String(localized: "Enable HTTPS MitM", comment: "CapabilityFlags for HTTPS MitM")
    case .rewrite:
      return String(localized: "Enable Rewrite", comment: "CapabilityFlags for Rewrite")
    case .scripting:
      return String(
        localized: "Enable Scripting",
        comment: "CapabilityFlags for Scripting"
      )
    default: return "UNKNOWN(\(self.rawValue))"
    }
  }
}

extension CapabilityFlags {

  public static var allCases: [CapabilityFlags] {
    [.httpCapture, .httpsDecryption, .rewrite, .scripting]
  }
}
