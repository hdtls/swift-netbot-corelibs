// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData)
  import SwiftData
#else
  import NetbotSQL
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  @Model public class AnyProxy {

    #Unique<AnyProxy>([\.name])

    /// The name of this policy.
    @Attribute(.unique)
    public var name = UUID().uuidString

    public typealias Source = NetbotProfile.AnyProxy.Source

    /// Source of this policy.
    public var source = Source.userDefined.rawValue

    public typealias Kind = NetbotProfile.AnyProxy.Kind

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
    public typealias Obfuscation = NetbotProfile.AnyProxy.Obfuscation

    /// The data obfuscation settings.
    public var obfuscation = Obfuscation()

    /// Policy for internet latency test..
    public var measurePolicy = MeasurePolicy()

    /// Metrics for latency tests.
    public var transactionMetrics = TransactionMetrics()

    /// WebSocket settings for VMESS protocol.
    public typealias TLS = NetbotProfile.AnyProxy.TLS

    /// TLS configuration used to secure transport connections make by this policy.
    public var tls = TLS()

    /// WebSocket settings for VMESS protocol.
    public typealias WebSocket = NetbotProfile.AnyProxy.WebSocket

    /// WebSocket settings for VMESS protocol.
    public var ws = WebSocket()

    /// Engress IP settings
    public typealias Engress = NetbotProfile.AnyProxy.Engress

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

    /// Relationship with `AnyProxyGroup.Model`.
    @Relationship(inverse: \AnyProxyGroup.lazyProxies)
    public var lazyProxyGroups: [AnyProxyGroup] = []

    /// Relationship with `AnyForwardingRule.Model`.
    @Relationship(inverse: \AnyForwardingRule.lazyProxy)
    public var lazyForwardingRules: [AnyForwardingRule] = []

    /// Relationship with `Profile`.
    public var lazyProfile: Profile?

    /// Create an instance of `AnyPolicy` with default values.
    public init() {
    }

    public var isEditable: Bool {
      kind.isProxyable
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.AnyProxy {

  /// Merge new values from DTO.
  /// - Parameter data: New `AnyProxy` to merge.
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
    measurePolicy = data.measurePolicy
    transactionMetrics = data.transactionMetrics
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
