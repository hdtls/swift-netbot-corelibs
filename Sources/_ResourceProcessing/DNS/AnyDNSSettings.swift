//
// See LICENSE.txt for license information
//

public struct AnyDNSSettings: Codable, Equatable, Hashable, Sendable {

  /// The DNS protocol used by the server, such as HTTPS or TLS.
  public var dnsProtocol: DNSProtocol = .cleartext

  /// The DNS server addresses.
  public var servers: [String] = []

  /// The DNS over TLS server name.
  public var serverName: String = ""

  /// The DNS over HTTPS server url.
  public var serverURLString: String = ""

  /// Initialize the DNSSetting object.
  public init(servers: [String]) {
    self.dnsProtocol = .cleartext
    self.servers = servers
  }

  public mutating func feedExtraValue(_ value: String) {
    switch value {
    case _ where value.hasPrefix("https://"):
      dnsProtocol = .https
      serverURLString = value
    case _ where value.hasPrefix("quic://"):
      dnsProtocol = .quic
      serverURLString = value
    default:
      dnsProtocol = .tls
      serverName = value
    }
  }
}

public enum DNSProtocol: Int, Codable, Hashable, Sendable {
  case cleartext
  case tls
  case https
  case quic
}
