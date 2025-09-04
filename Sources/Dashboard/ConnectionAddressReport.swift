//
// See LICENSE.txt for license information
//

/// A connection address report allows a caller to set metadata about connection being sent between endpoints.
@available(SwiftStdlib 5.3, *)
public struct ConnectionAddressReport: Codable, Hashable, Sendable {

  /// Remote hostname whitch this connection was sent.
  /// May be IP address or hostname.
  public var hostname: String

  /// Port that connection was connected.
  public var port: Int

  /// Local IP address that sent this connection
  public var localIPAddress: String = "N/A"

  /// Remote IP address whitch this connection was sent.
  public var remoteIPAddress: String = "N/A"

  /// Remote IP address region.
  public var remoteIPAddressRegion: String = "N/A"

  /// Remote IP address ASN.
  public var remoteIPAddressASN: String = "N/A"

  /// Remote IP address ASO.
  public var remoteIPAddressASO: String = "N/A"

  public init(
    hostname: String,
    port: Int,
    localIPAddress: String = "N/A",
    remoteIPAddress: String = "N/A",
    remoteIPAddressRegion: String = "N/A",
    remoteIPAddressASN: String = "N/A",
    remoteIPAddressASO: String = "N/A"
  ) {
    self.hostname = hostname
    self.port = port
    self.localIPAddress = localIPAddress
    self.remoteIPAddress = remoteIPAddress
    self.remoteIPAddressRegion = remoteIPAddressRegion
    self.remoteIPAddressASN = remoteIPAddressASN
    self.remoteIPAddressASO = remoteIPAddressASO
  }
}
