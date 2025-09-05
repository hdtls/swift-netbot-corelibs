//
// See LICENSE.txt for license information
//

import CoWOptimization
import Logging

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
@_cowOptimization public struct Profile: Equatable, Hashable, Sendable {

  /// The url the resource was storaged..
  public var url: URL

  /// Log level use for `Logger`.`
  public var logLevel: Logger.Level

  /// DNS settings.
  public var dnsSettings: AnyDNSSettings

  /// Exceptions use for system proxy.
  public var exceptions: [String]

  /// Http listen address use for system http proxy.
  public var httpListenAddress: String

  /// Http listen port use for system http proxy
  public var httpListenPort: Int?

  /// Socks listen address use for system socks proxy.
  public var socksListenAddress: String

  /// Socks listen port use for system socks proxy.
  public var socksListenPort: Int?

  /// A boolean value that determine whether system proxy should exclude simple hostnames.
  public var excludeSimpleHostnames: Bool

  /// A boolean value determine whether ssl should skip server cerfitication verification. Default is false.
  public var skipCertificateVerification: Bool

  /// Hostnames that should perform MitM.
  public var hostnames: [String]

  /// Base64 encoded CA P12 bundle.
  public var base64EncodedP12String: String

  /// Passphrase for P12 bundle.
  public var passphrase: String

  /// The time the resource content was last modified.
  public var contentModificationDate: Date

  /// Global internet connect quality test URL string.
  public var testURL: URL?

  /// Global proxy connect quality test URL string.
  public var proxyTestURL: URL?

  /// Timeout for network measurement.
  public var testTimeout: Double

  /// A boolean value determine whether show error pages for REJECT policy errors should be disabled.
  public var dontAlertRejectErrors: Bool

  /// A boolean value determine whether remote access should be disabled.
  public var dontAllowRemoteAccess: Bool

  /// The time the resource was created.
  public var creationDate: Date

  /// The proxies included in this profile.
  public var lazyProxies: [AnyProxy]

  /// The policy groups included in this profile.
  public var lazyProxyGroups: [AnyProxyGroup]

  /// The rules included in this profile.
  public var lazyForwardingRules: [AnyForwardingRule]

  /// The DNS mappings included in this profile.
  public var lazyDNSMappings: [DNSMapping]

  /// The URL rewriting included in this profile.
  public var lazyURLRewrites: [URLRewrite]

  /// The HTTP fields rewriting included in this profile.
  public var lazyHTTPFieldsRewrites: [HTTPFieldsRewrite]

  /// The stubbed HTTP responses included in this profile.
  public var lazyStubbedHTTPResponses: [StubbedHTTPResponse]

  /// Initialize a `Profile`  using specific url.
  public init(
    url: URL = .profile,
    logLevel: Logger.Level = Logger.Level.info,
    dnsSettings: AnyDNSSettings = AnyDNSSettings(servers: []),
    exceptions: [String] = [],
    httpListenAddress: String = "127.0.0.1",
    httpListenPort: Int? = nil,
    socksListenAddress: String = "127.0.0.1",
    socksListenPort: Int? = nil,
    excludeSimpleHostnames: Bool = false,
    skipCertificateVerification: Bool = false,
    hostnames: [String] = [],
    base64EncodedP12String: String = "",
    passphrase: String = "",
    testURL: URL? = nil,
    proxyTestURL: URL? = nil,
    testTimeout: Double = 5.0,
    dontAlertRejectErrors: Bool = false,
    dontAllowRemoteAccess: Bool = false,
    lazyProxies: [AnyProxy] = [],
    lazyProxyGroups: [AnyProxyGroup] = [],
    lazyForwardingRules: [AnyForwardingRule] = [],
    lazyDNSMappings: [DNSMapping] = [],
    lazyURLRewrites: [URLRewrite] = [],
    lazyHTTPFieldsRewrites: [HTTPFieldsRewrite] = [],
    lazyStubbedHTTPResponses: [StubbedHTTPResponse] = []
  ) {
    let creationDate: Date
    let contentModificationDate: Date
    if #available(SwiftStdlib 5.5, *) {
      creationDate = .now
      contentModificationDate = .now
    } else {
      creationDate = .init()
      contentModificationDate = .init()
    }
    _storage = _Storage(
      url: url,
      logLevel: logLevel,
      dnsSettings: dnsSettings,
      exceptions: exceptions,
      httpListenAddress: httpListenAddress,
      httpListenPort: httpListenPort,
      socksListenAddress: socksListenAddress,
      socksListenPort: socksListenPort,
      excludeSimpleHostnames: excludeSimpleHostnames,
      skipCertificateVerification: skipCertificateVerification,
      hostnames: hostnames,
      base64EncodedP12String: base64EncodedP12String,
      passphrase: passphrase,
      contentModificationDate: contentModificationDate,
      testURL: testURL,
      proxyTestURL: proxyTestURL,
      testTimeout: testTimeout,
      dontAlertRejectErrors: dontAlertRejectErrors,
      dontAllowRemoteAccess: dontAllowRemoteAccess,
      creationDate: creationDate,
      lazyProxies: lazyProxies,
      lazyProxyGroups: lazyProxyGroups,
      lazyForwardingRules: lazyForwardingRules,
      lazyDNSMappings: lazyDNSMappings,
      lazyURLRewrites: lazyURLRewrites,
      lazyHTTPFieldsRewrites: lazyHTTPFieldsRewrites,
      lazyStubbedHTTPResponses: lazyStubbedHTTPResponses
    )
  }
}

@available(SwiftStdlib 5.3, *)
extension Profile._Storage: Hashable {
  @inlinable static func == (lhs: Profile._Storage, rhs: Profile._Storage) -> Bool {
    lhs.url == rhs.url
      && lhs.logLevel == rhs.logLevel
      && lhs.dnsSettings == rhs.dnsSettings
      && lhs.exceptions == rhs.exceptions
      && lhs.httpListenAddress == rhs.httpListenAddress
      && lhs.httpListenPort == rhs.httpListenPort
      && lhs.socksListenAddress == rhs.socksListenAddress
      && lhs.socksListenPort == rhs.socksListenPort
      && lhs.skipCertificateVerification == rhs.skipCertificateVerification
      && lhs.hostnames == rhs.hostnames
      && lhs.base64EncodedP12String == rhs.base64EncodedP12String
      && lhs.dontAlertRejectErrors == rhs.dontAlertRejectErrors
      && lhs.dontAllowRemoteAccess == rhs.dontAllowRemoteAccess
      && lhs.creationDate == rhs.creationDate
      && lhs.lazyProxyGroups == rhs.lazyProxyGroups
      && lhs.lazyForwardingRules == rhs.lazyForwardingRules
      && lhs.lazyDNSMappings == rhs.lazyDNSMappings
      && lhs.lazyURLRewrites == rhs.lazyURLRewrites
      && lhs.lazyHTTPFieldsRewrites == rhs.lazyHTTPFieldsRewrites
      && lhs.lazyStubbedHTTPResponses == rhs.lazyStubbedHTTPResponses
  }

  @inlinable func hash(into hasher: inout Hasher) {
    hasher.combine(url)
    hasher.combine(logLevel)
    hasher.combine(dnsSettings)
    hasher.combine(exceptions)
    hasher.combine(httpListenAddress)
    hasher.combine(httpListenPort)
    hasher.combine(socksListenAddress)
    hasher.combine(socksListenPort)
    hasher.combine(excludeSimpleHostnames)
    hasher.combine(skipCertificateVerification)
    hasher.combine(hostnames)
    hasher.combine(base64EncodedP12String)
    hasher.combine(passphrase)
    hasher.combine(contentModificationDate)
    hasher.combine(testURL)
    hasher.combine(proxyTestURL)
    hasher.combine(testTimeout)
    hasher.combine(dontAlertRejectErrors)
    hasher.combine(dontAllowRemoteAccess)
    hasher.combine(creationDate)
    hasher.combine(lazyProxies)
    hasher.combine(lazyProxyGroups)
    hasher.combine(lazyForwardingRules)
    hasher.combine(lazyDNSMappings)
    hasher.combine(lazyURLRewrites)
    hasher.combine(lazyHTTPFieldsRewrites)
    hasher.combine(lazyStubbedHTTPResponses)
  }
}

@available(SwiftStdlib 5.3, *)
extension Profile._Storage: @unchecked Sendable {}

@available(SwiftStdlib 5.3, *)
extension Profile {

  public init(contentsOf url: URL) throws {
    let parseInput: String
    if #available(SwiftStdlib 5.7, *) {
      parseInput = try String(contentsOf: url, encoding: .utf8)
    } else {
      parseInput = try String(contentsOfFile: url.path, encoding: .utf8)
    }
    self = try Profile.FormatStyle().parse(parseInput)
    self.url = url
  }
}
