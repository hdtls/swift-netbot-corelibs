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

import Logging

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

  @Model public class Profile {

    #Unique<Profile>([\.url])

    /// The url the resource was storaged.
    @Attribute(.unique)
    public var url = URL.profile

    /// Log level use for `Logger`.`
    public var logLevel = Logger.Level.info

    /// DNS settings.
    public var dnsSettings = AnyDNSSettings(servers: [])

    /// Exceptions use for system proxy.
    public var exceptions: [String] {
      get { _exceptions.split(separator: ",").map(String.init) }
      set { _exceptions = newValue.joined(separator: ",") }
    }
    public var _exceptions: String = ""

    /// Http listen address use for system http proxy.
    public var httpListenAddress = "0.0.0.0"

    /// Http listen port use for system http proxy
    public var httpListenPort: Int?

    /// Socks listen address use for system socks proxy.
    public var socksListenAddress = "0.0.0.0"

    /// Socks listen port use for system socks proxy.
    public var socksListenPort: Int?

    /// A boolean value that determine whether system proxy should exclude simple hostnames.
    public var excludeSimpleHostnames = false

    /// A boolean value determine whether ssl should skip server cerfitication verification. Default is false.
    public var skipCertificateVerification = false

    /// Hostnames that should perform MitM.
    public var hostnames: [String] {
      get { _hostnames.split(separator: ",").map(String.init) }
      set { _hostnames = newValue.joined(separator: ",") }
    }
    public var _hostnames: String = ""

    /// Base64 encoded CA P12 bundle.
    public var base64EncodedP12String = ""

    /// Passphrase for P12 bundle.
    public var passphrase = ""

    /// The time the resource content was last modified.
    public var contentModificationDate = Date.now

    /// Global internet connect quality test URL string.
    public var testURL: URL?

    /// Global proxy connect quality test URL string.
    public var proxyTestURL: URL?

    /// Timeout for network measurement.
    public var testTimeout = 5.0

    /// A boolean value determine whether show error pages for REJECT policy errors should be disabled.
    public var dontAlertRejectErrors = false

    /// A boolean value determine whether remote access should be disabled.
    public var dontAllowRemoteAccess = false

    /// The time the resource was created.
    public var creationDate = Date.now

    /// The proxies included in this profile.
    @Relationship(inverse: \AnyProxy.lazyProfile)
    public var lazyProxies: [AnyProxy] = []

    /// The policy groups included in this profile.
    @Relationship(inverse: \AnyProxyGroup.lazyProfile)
    public var lazyProxyGroups: [AnyProxyGroup] = []

    /// The rules included in this profile.
    @Relationship(inverse: \AnyForwardingRule.lazyProfile)
    public var lazyForwardingRules: [AnyForwardingRule] = []

    /// The DNS mappings included in this profile.
    @Relationship(inverse: \ProtocolDNS.Mapping.lazyProfile)
    public var lazyDNSMappings: [ProtocolDNS.Mapping] = []

    /// The URL rewriting included in this profile.
    @Relationship(inverse: \URLRewrite.lazyProfile)
    public var lazyURLRewrites: [URLRewrite] = []

    /// The HTTP fields rewriting included in this profile.
    @Relationship(inverse: \HTTPFieldsRewrite.lazyProfile)
    public var lazyHTTPFieldsRewrites: [HTTPFieldsRewrite] = []

    /// The stubbed HTTP responses included in this profile.
    @Relationship(inverse: \StubbedHTTPResponse.lazyProfile)
    public var lazyStubbedHTTPResponses: [StubbedHTTPResponse] = []

    /// Initialize a `Profile` using default url.
    public init() {}
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.Profile {

  /// Merge new values from DTO.
  /// - Parameter data: New `Profile` to merge.
  public func mergeValues(_ data: Profile) {
    url = data.url
    logLevel = data.logLevel
    dnsSettings = data.dnsSettings
    exceptions = data.exceptions
    httpListenAddress = data.httpListenAddress
    httpListenPort = data.httpListenPort
    socksListenAddress = data.socksListenAddress
    socksListenPort = data.socksListenPort
    excludeSimpleHostnames = data.excludeSimpleHostnames
    skipCertificateVerification = data.skipCertificateVerification
    hostnames = data.hostnames
    base64EncodedP12String = data.base64EncodedP12String
    passphrase = data.passphrase
    contentModificationDate = data.contentModificationDate
    testURL = data.testURL
    proxyTestURL = data.proxyTestURL
    testTimeout = data.testTimeout
    dontAlertRejectErrors = data.dontAlertRejectErrors
    dontAllowRemoteAccess = data.dontAllowRemoteAccess
    creationDate = data.creationDate
  }
}
