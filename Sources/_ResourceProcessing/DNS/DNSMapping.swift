//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import FoundationEssentials
#else
  public import Foundation
#endif

/// An Object declaring DNS mapping rules.
public struct DNSMapping: Equatable, Hashable, Sendable {

  /// Kind of the mDNS apping.
  public enum Kind: Int, CaseIterable, Codable, Hashable, Sendable {
    /// Map resolved IP address.
    case mapping

    /// Map new domain name.
    case cname

    /// Map domain name resolution server.
    case dns
  }

  /// The kind of the mapping.
  public var kind = Kind.mapping

  /// A boolean value determinse whether this mapping is enabled.
  public var isEnabled = true

  /// The domain to perform local DNS mapping.
  public var domainName = ""

  /// The mapped value.
  ///
  /// When the `kind` value is `mapping`, the value represents the mapped IP address.
  /// When the `kind` value is `cname`, the value represents the mapped new domain name.
  /// When the `kind` value is `dns`, the value represents the new domain name resolution server.
  public var value = ""

  /// The note on this DNS mapping.
  public var note = ""

  /// The date when the mapping created.
  public var creationDate: Date

  /// Initialize an instance of `DNSMapping` object with specified `domainName`.
  public init(kind: Kind = .mapping, domainName: String = "", value: String = "", note: String = "")
  {
    self.domainName = domainName
    self.value = value
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
      self.creationDate = .now
    } else {
      self.creationDate = .init()
    }
  }
}
