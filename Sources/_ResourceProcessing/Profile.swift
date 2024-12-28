//
// See LICENSE.txt for license information
//

public import Logging

#if canImport(FoundationEssentials)
  public import FoundationEssentials
#else
  public import Foundation
#endif

public struct Profile: Equatable, Hashable {

  @usableFromInline final class _Storage: Equatable, Hashable {

    /// The url the resource was storaged..
    @usableFromInline var url: URL

    /// Log level use for `Logger`.`
    @usableFromInline var logLevel: Logger.Level

    /// DNS settings.
    @usableFromInline var dnsSettings: AnyDNSSettings

    /// Exceptions use for system proxy.
    @usableFromInline var exceptions: [String]

    /// Http listen address use for system http proxy.
    @usableFromInline var httpListenAddress: String

    /// Http listen port use for system http proxy
    @usableFromInline var httpListenPort: Int?

    /// Socks listen address use for system socks proxy.
    @usableFromInline var socksListenAddress: String

    /// Socks listen port use for system socks proxy.
    @usableFromInline var socksListenPort: Int?

    /// A boolean value that determine whether system proxy should exclude simple hostnames.
    @usableFromInline var excludeSimpleHostnames: Bool

    /// A boolean value determine whether ssl should skip server cerfitication verification. Default is false.
    @usableFromInline var skipCertificateVerification: Bool

    /// Hostnames that should perform MitM.
    @usableFromInline var hostnames: [String] = []

    /// Base64 encoded CA P12 bundle.
    @usableFromInline var base64EncodedP12String: String

    /// Passphrase for P12 bundle.
    @usableFromInline var passphrase: String

    /// The time the resource content was last modified.
    @usableFromInline var contentModificationDate: Date

    /// Global internet connect quality test URL string.
    @usableFromInline var testURL: URL?

    /// Global proxy connect quality test URL string.
    @usableFromInline var proxyTestURL: URL?

    /// Timeout for network measurement.
    @usableFromInline var testTimeout: Double

    /// A boolean value determine whether show error pages for REJECT policy errors should be disabled.
    @usableFromInline var dontAlertRejectErrors: Bool

    /// A boolean value determine whether remote access should be disabled.
    @usableFromInline var dontAllowRemoteAccess: Bool

    /// The time the resource was created.
    @usableFromInline var creationDate: Date

    /// The proxies included in this profile.
    @usableFromInline var lazyProxies: [AnyProxy]

    /// The policy groups included in this profile.
    @usableFromInline var lazyProxyGroups: [AnyProxyGroup]

    /// The rules included in this profile.
    @usableFromInline var lazyForwardingRules: [AnyForwardingRule]

    /// The DNS mappings included in this profile.
    @usableFromInline var lazyDNSMappings: [DNSMapping]

    /// The URL rewriting included in this profile.
    @usableFromInline var lazyURLRewrites: [URLRewrite]

    /// The HTTP fields rewriting included in this profile.
    @usableFromInline var lazyHTTPFieldsRewrites: [HTTPFieldsRewrite]

    /// The stubbed HTTP responses included in this profile.
    @usableFromInline var lazyStubbedHTTPResponses: [StubbedHTTPResponse]

    @inlinable init(
      url: URL,
      logLevel: Logger.Level,
      dnsSettings: AnyDNSSettings,
      exceptions: [String],
      httpListenAddress: String,
      httpListenPort: Int?,
      socksListenAddress: String,
      socksListenPort: Int?,
      excludeSimpleHostnames: Bool,
      skipCertificateVerification: Bool,
      hostnames: [String],
      base64EncodedP12String: String,
      passphrase: String,
      contentModificationDate: Date,
      testURL: URL?,
      proxyTestURL: URL?,
      testTimeout: Double,
      dontAlertRejectErrors: Bool,
      dontAllowRemoteAccess: Bool,
      creationDate: Date,
      lazyProxies: [AnyProxy],
      lazyProxyGroups: [AnyProxyGroup],
      lazyForwardingRules: [AnyForwardingRule],
      lazyDNSMappings: [DNSMapping],
      lazyURLRewrites: [URLRewrite],
      lazyHTTPFieldsRewrites: [HTTPFieldsRewrite],
      lazyStubbedHTTPResponses: [StubbedHTTPResponse]
    ) {
      self.url = url
      self.logLevel = logLevel
      self.dnsSettings = dnsSettings
      self.exceptions = exceptions
      self.httpListenAddress = httpListenAddress
      self.httpListenPort = httpListenPort
      self.socksListenAddress = socksListenAddress
      self.socksListenPort = socksListenPort
      self.excludeSimpleHostnames = excludeSimpleHostnames
      self.skipCertificateVerification = skipCertificateVerification
      self.hostnames = hostnames
      self.base64EncodedP12String = base64EncodedP12String
      self.passphrase = passphrase
      self.contentModificationDate = contentModificationDate
      self.testURL = testURL
      self.proxyTestURL = proxyTestURL
      self.testTimeout = testTimeout
      self.dontAlertRejectErrors = dontAlertRejectErrors
      self.dontAllowRemoteAccess = dontAllowRemoteAccess
      self.creationDate = creationDate
      self.lazyProxies = lazyProxies
      self.lazyProxyGroups = lazyProxyGroups
      self.lazyForwardingRules = lazyForwardingRules
      self.lazyDNSMappings = lazyDNSMappings
      self.lazyURLRewrites = lazyURLRewrites
      self.lazyHTTPFieldsRewrites = lazyHTTPFieldsRewrites
      self.lazyStubbedHTTPResponses = lazyStubbedHTTPResponses
    }

    @usableFromInline static func == (lhs: Profile._Storage, rhs: Profile._Storage) -> Bool {
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

    @usableFromInline func hash(into hasher: inout Hasher) {
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

    @inlinable func copy() -> _Storage {
      _Storage(
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

  @usableFromInline var _storage: _Storage

  /// The url the resource was storaged..
  @inlinable public var url: URL {
    get { _storage.url }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.url = newValue
    }
  }

  /// Log level use for `Logger`.`
  @inlinable public var logLevel: Logger.Level {
    get { _storage.logLevel }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.logLevel = newValue
    }
  }

  /// DNS settings.
  @inlinable public var dnsSettings: AnyDNSSettings {
    get { _storage.dnsSettings }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.dnsSettings = newValue
    }
  }

  /// Exceptions use for system proxy.
  @inlinable public var exceptions: [String] {
    get { _storage.exceptions }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.exceptions = newValue
    }
  }

  /// Http listen address use for system http proxy.
  @inlinable public var httpListenAddress: String {
    get { _storage.httpListenAddress }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.httpListenAddress = newValue
    }
  }

  /// Http listen port use for system http proxy
  @inlinable public var httpListenPort: Int? {
    get { _storage.httpListenPort }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.httpListenPort = newValue
    }
  }

  /// Socks listen address use for system socks proxy.
  @inlinable public var socksListenAddress: String {
    get { _storage.socksListenAddress }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.socksListenAddress = newValue
    }
  }

  /// Socks listen port use for system socks proxy.
  @inlinable public var socksListenPort: Int? {
    get { _storage.socksListenPort }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.socksListenPort = newValue
    }
  }

  /// A boolean value that determine whether system proxy should exclude simple hostnames.
  @inlinable public var excludeSimpleHostnames: Bool {
    get { _storage.excludeSimpleHostnames }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.excludeSimpleHostnames = newValue
    }
  }

  /// A boolean value determine whether ssl should skip server cerfitication verification. Default is false.
  @inlinable public var skipCertificateVerification: Bool {
    get { _storage.skipCertificateVerification }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.skipCertificateVerification = newValue
    }
  }

  /// Hostnames that should perform MitM.
  @inlinable public var hostnames: [String] {
    get { _storage.hostnames }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.hostnames = newValue
    }
  }

  /// Base64 encoded CA P12 bundle.
  @inlinable public var base64EncodedP12String: String {
    get { _storage.base64EncodedP12String }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.base64EncodedP12String = newValue
    }
  }

  /// Passphrase for P12 bundle.
  @inlinable public var passphrase: String {
    get { _storage.passphrase }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.passphrase = newValue
    }
  }

  /// The time the resource content was last modified.
  @inlinable public var contentModificationDate: Date {
    get { _storage.contentModificationDate }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.contentModificationDate = newValue
    }
  }

  /// Global internet connect quality test URL string.
  @inlinable public var testURL: URL? {
    get { _storage.testURL }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.testURL = newValue
    }
  }

  /// Global proxy connect quality test URL string.
  @inlinable public var proxyTestURL: URL? {
    get { _storage.proxyTestURL }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.proxyTestURL = newValue
    }
  }

  /// Timeout for network measurement.
  @inlinable public var testTimeout: Double {
    get { _storage.testTimeout }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.testTimeout = newValue
    }
  }

  /// A boolean value determine whether show error pages for REJECT policy errors should be disabled.
  @inlinable public var dontAlertRejectErrors: Bool {
    get { _storage.dontAlertRejectErrors }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.dontAlertRejectErrors = newValue
    }
  }

  /// A boolean value determine whether remote access should be disabled.
  @inlinable public var dontAllowRemoteAccess: Bool {
    get { _storage.dontAllowRemoteAccess }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.dontAllowRemoteAccess = newValue
    }
  }

  /// The time the resource was created.
  @inlinable public var creationDate: Date {
    get { _storage.creationDate }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.creationDate = newValue
    }
  }

  /// The proxies included in this profile.
  public var lazyProxies: [AnyProxy] {
    get { _storage.lazyProxies }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.lazyProxies = newValue
    }
  }

  /// The policy groups included in this profile.
  public var lazyProxyGroups: [AnyProxyGroup] {
    get { _storage.lazyProxyGroups }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.lazyProxyGroups = newValue
    }
  }

  /// The rules included in this profile.
  public var lazyForwardingRules: [AnyForwardingRule] {
    get { _storage.lazyForwardingRules }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.lazyForwardingRules = newValue
    }
  }

  /// The DNS mappings included in this profile.
  public var lazyDNSMappings: [DNSMapping] {
    get { _storage.lazyDNSMappings }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.lazyDNSMappings = newValue
    }
  }

  /// The URL rewriting included in this profile.
  public var lazyURLRewrites: [URLRewrite] {
    get { _storage.lazyURLRewrites }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.lazyURLRewrites = newValue
    }
  }

  /// The HTTP fields rewriting included in this profile.
  public var lazyHTTPFieldsRewrites: [HTTPFieldsRewrite] {
    get { _storage.lazyHTTPFieldsRewrites }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.lazyHTTPFieldsRewrites = newValue
    }
  }

  /// The stubbed HTTP responses included in this profile.
  public var lazyStubbedHTTPResponses: [StubbedHTTPResponse] {
    get { _storage.lazyStubbedHTTPResponses }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.lazyStubbedHTTPResponses = newValue
    }
  }

  /// Initialize a `Profile`  using specific url.
  @inlinable public init(
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
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
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

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }
}

extension Profile: @unchecked Sendable {}

@available(*, unavailable)
extension Profile._Storage: @unchecked Sendable {}

extension Profile {

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public init(contentsOf url: URL) throws {
    let parseInput = try String(contentsOf: url, encoding: .utf8)
    self = try Profile(parseInput, strategy: .profile)
    self.url = url
  }
}
