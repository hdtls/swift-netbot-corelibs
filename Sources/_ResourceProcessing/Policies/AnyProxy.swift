//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import FoundationEssentials
#else
  public import Foundation
#endif

public struct AnyProxy: Equatable, Hashable, Sendable {

  /// The name of this policy.
  public var name: String

  /// Source of this policy.
  public var source = Source.userDefined

  /// Policy type, defaults to `http`.
  public var kind = Kind.http

  /// Proxy server address.
  public var serverAddress = ""

  /// Proxy server port.
  public var port = 0

  /// Username for proxy authentication.
  ///
  /// - note: For VMESS protocol username *MUST* be an UUID string.
  public var username = ""

  /// Password for HTTP basic authentication and SOCKS5 username password authentication.
  public var passwordReference = ""

  /// ALPN for TUIC.
  public var alpn = ""

  /// A boolean value determinse whether connection should perform username password authentication.
  ///
  /// - note: This is used in HTTP/HTTPS basic authentication and SOCKS/SOCKS over TLS username/password authentication.
  public var authenticationRequired = false

  /// SS encryption and decryption algorithm.
  ///
  /// - note: This is used in Shadowsocks protocol.
  public var algorithm = Algorithm.aes128Gcm

  /// The data obfuscation settings.
  public var obfuscation = Obfuscation()

  /// Network measurements.
  public var measurement = Measurement()

  /// TLS configuration used to secure transport connections make by this policy.
  public var tls = TLS()

  /// WebSocket settings for VMESS protocol.
  public var ws = WebSocket()

  /// Engress controls settings.
  public var engress = Engress()

  /// A boolean value determine whether should forward UDP packets to the proxy server.
  public var allowUDPRelay = false

  /// A boolean value determine whether should enable TCP fast open.
  public var isTFOEnabled = false

  /// A boolean value determinse whether HTTP proxy should prefer using CONNECT tunnel.
  public var forceHTTPTunneling = false

  /// A boolean value determinse whether the policy should alert when error occurred, defaults to false.
  public var dontAlertError = false

  /// The policy's creation date.
  public var creationDate: Date

  public init(
    name: String = UUID().uuidString,
    source: Source = .userDefined,
    kind: Kind = Kind.http,
    serverAddress: String = "",
    port: Int = 0,
    username: String = "",
    passwordReference: String = "",
    alpn: String = "",
    authenticationRequired: Bool = false,
    algorithm: Algorithm = Algorithm.aes128Gcm,
    obfuscation: AnyProxy.Obfuscation = Obfuscation(),
    measurement: AnyProxy.Measurement = Measurement(),
    tls: AnyProxy.TLS = TLS(),
    ws: AnyProxy.WebSocket = WebSocket(),
    engress: AnyProxy.Engress = Engress(),
    allowUDPRelay: Bool = false,
    isTFOEnabled: Bool = false,
    forceHTTPTunneling: Bool = false,
    dontAlertError: Bool = false
  ) {
    self.name = name
    self.source = source
    self.kind = kind
    self.serverAddress = serverAddress
    self.port = port
    self.username = username
    self.passwordReference = passwordReference
    self.alpn = alpn
    self.authenticationRequired = authenticationRequired
    self.algorithm = algorithm
    self.obfuscation = obfuscation
    self.measurement = measurement
    self.tls = tls
    self.ws = ws
    self.engress = engress
    self.allowUDPRelay = allowUDPRelay
    self.isTFOEnabled = isTFOEnabled
    self.forceHTTPTunneling = forceHTTPTunneling
    self.dontAlertError = dontAlertError
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
      self.creationDate = .now
    } else {
      self.creationDate = .init()
    }
  }
}
