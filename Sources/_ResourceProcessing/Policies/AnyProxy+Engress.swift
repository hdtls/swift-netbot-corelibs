//
// See LICENSE.txt for license information
//

extension AnyProxy {
  /// Engress IP settings
  public struct Engress: Codable, Hashable, Sendable {

    /// The name of binded network interface.
    public var interfaceName: String = ""

    /// A boolean value determine whether should fallback to use default interface if current defined interface is unavailable.
    public var backToDefaultIfNICUnavailable: Bool = false

    /// IP type of service.
    ///
    /// For more information see RFC1340 and RFC1349
    public var packetToS: UInt8 = 0

    public enum VersionStrategy: String, CaseIterable, Codable, Hashable, Sendable {
      case v4
      case v6
      case dual
    }

    public var versionStrategy = VersionStrategy.dual

    /// Initialize an instance of `EngressIP` with specified packetToS and versionStrategy.
    public init(packetToS: UInt8 = 0, versionStrategy: VersionStrategy = .dual) {
      self.packetToS = packetToS
      self.versionStrategy = versionStrategy
    }
  }
}
