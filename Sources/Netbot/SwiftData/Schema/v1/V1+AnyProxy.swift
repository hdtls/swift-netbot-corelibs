//
// See LICENSE.txt for license information
//

import _ResourceProcessing

#if canImport(SwiftData)
  import Foundation
  import SwiftData

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension V1 {

    @Model public class _AnyProxy {

      /// The name of this policy.
      @Attribute(.unique)
      public var name = UUID().uuidString

      public typealias Source = AnyProxy.Source

      /// Source of this policy.
      public var source = Source.userDefined.rawValue

      public typealias Kind = AnyProxy.Kind

      /// Policy type, defaults to `http`.
      public var kind = Kind.http

      /// Proxy server address.
      public var serverAddress = ""

      /// Proxy server port.
      public var port = 0

      /// Username for proxy authentication.
      ///
      /// - note: For VMESS protocol username *MUST* be an UUID string.
      public var username: String?

      /// Password for HTTP basic authentication and SOCKS5 username password authentication.
      public var passwordReference: String?

      /// ALPN for TUIC.
      public var alpn: String?

      /// A boolean value determinse whether connection should perform username password authentication.
      ///
      /// - note: This is used in HTTP/HTTPS basic authentication and SOCKS/SOCKS over TLS username/password authentication.
      public var authenticationRequired = false

      /// SS encryption and decryption algorithm.
      ///
      /// - note: This is used in Shadowsocks protocol.
      public var algorithm = Algorithm.aes128Gcm

      /// Data obfuscation settings.
      public typealias Obfuscation = AnyProxy.Obfuscation

      /// The data obfuscation settings.
      public var obfuscation = Obfuscation()

      /// An object representing network measurements.
      public typealias Measurement = AnyProxy.Measurement

      /// Network measurements.
      public var measurement = Measurement()

      /// WebSocket settings for VMESS protocol.
      public typealias TLS = AnyProxy.TLS

      /// TLS configuration used to secure transport connections make by this policy.
      public var tls = TLS()

      /// WebSocket settings for VMESS protocol.
      public typealias WebSocket = AnyProxy.WebSocket

      /// WebSocket settings for VMESS protocol.
      public var ws = WebSocket()

      /// Engress IP settings
      public typealias Engress = AnyProxy.Engress

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
      public var creationDate = Date.now

      /// Relationship with `AnyProxyGroup.PersistentModel`.
      @Relationship(inverse: \_AnyProxyGroup.lazyProxies)
      public var lazyProxyGroups: [_AnyProxyGroup] = []

      /// Relationship with `AnyForwardingRule.PersistentModel`.
      @Relationship(inverse: \_AnyForwardingRule.lazyProxy)
      public var lazyForwardingRules: [_AnyForwardingRule] = []

      /// Relationship with `_Profile`.
      public var lazyProfile: _Profile?

      /// Create an instance of `AnyPolicy` with default values.
      public init() {
      }

      public var isEditable: Bool {
        kind.isProxyable
      }
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension AnyProxy {

    public typealias PersistentModel = V1._AnyProxy

    public init(persistentModel: PersistentModel) {
      self.init()
      name = persistentModel.name
      source = .init(rawValue: persistentModel.source) ?? .userDefined
      kind = persistentModel.kind
      serverAddress = persistentModel.serverAddress
      port = persistentModel.port
      username = persistentModel.username ?? ""
      passwordReference = persistentModel.passwordReference ?? ""
      alpn = persistentModel.alpn ?? ""
      authenticationRequired = persistentModel.authenticationRequired
      algorithm = persistentModel.algorithm
      obfuscation = persistentModel.obfuscation
      measurement = persistentModel.measurement
      tls = persistentModel.tls
      ws = persistentModel.ws
      engress = persistentModel.engress
      allowUDPRelay = persistentModel.allowUDPRelay
      isTFOEnabled = persistentModel.isTFOEnabled
      forceHTTPTunneling = persistentModel.forceHTTPTunneling
      dontAlertError = persistentModel.dontAlertError
      creationDate = persistentModel.creationDate
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension V1._AnyProxy {
    public func mergeValues(_ data: AnyProxy) {
      name = data.name
      source = data.source.rawValue
      kind = data.kind
      serverAddress = data.serverAddress
      port = data.port
      username = data.username
      passwordReference = data.passwordReference
      alpn = data.alpn
      authenticationRequired = data.authenticationRequired
      algorithm = data.algorithm
      obfuscation = data.obfuscation
      measurement = data.measurement
      tls = data.tls
      ws = data.ws
      engress = data.engress
      allowUDPRelay = data.allowUDPRelay
      isTFOEnabled = data.isTFOEnabled
      forceHTTPTunneling = data.forceHTTPTunneling
      dontAlertError = data.dontAlertError
      creationDate = data.creationDate
    }
  }
#endif
