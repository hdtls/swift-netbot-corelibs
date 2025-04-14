//
// See LICENSE.txt for license information
//

import HTTPTypes
import Testing

@testable import _ResourceProcessing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.proxy, .formatting))
struct AnyProxyFormatStyleTests {

  private let formatter = AnyProxy.FormatStyle()

  /// A AnyProxy modified all basic properties to undefault value.
  private var base: AnyProxy {
    var proxy = AnyProxy()
    proxy.serverAddress = "svr.example.com"
    proxy.port = 6152
    proxy.username = "username"
    proxy.passwordReference = "password"
    proxy.alpn = "h2"
    proxy.authenticationRequired = true
    proxy.algorithm = .aes256Gcm
    proxy.obfuscation = .init(isEnabled: true, strategy: .tls, hostname: "obfuscate.example.com")
    proxy.measurement.url = .init(string: "http://test.example.com")
    proxy.engress.interfaceName = "AirPort"
    proxy.engress.backToDefaultIfNICUnavailable = true
    proxy.engress.packetToS = 2
    proxy.engress.versionStrategy = .v4
    proxy.tls = .init()
    proxy.tls.isEnabled = true
    proxy.tls.skipCertificateVerification = true
    proxy.tls.sni = "sni.example.com"
    proxy.tls.certificatePinning = "wLgBEAGmLltnXbK6pzpvPMeOCTKZ0QwrWGem6DkNf6o="
    proxy.ws = .init()
    proxy.ws.isEnabled = true
    proxy.ws.uri = "/ws"
    proxy.ws.additionalHTTPFields = [.connection: "keep-alive"]
    proxy.allowUDPRelay = true
    proxy.isTFOEnabled = true
    proxy.forceHTTPTunneling = true
    proxy.dontAlertError = true
    return proxy
  }

  /// ParseInput include all possible fields undefault value fields.
  private var possibleParseInput: String {
    "VMESS = vmess, username = C51F3C92-EEF6-4506-A39F-C2D7786A50D7, password-reference = password, authentication-required = true, force-http-tunneling = true, alpn = h2, tls = true, tls.skip-certificate-verification = true, tls.sni = sni.example.com, tls.certificate-pinning = wLgBEAGmLltnXbK6pzpvPMeOCTKZ0QwrWGem6DkNf6o=, allow-udp-relay = true, algo = AES-256-GCM, obfs = true, obfs.strategy = 2, obfs.hostname = obfuscate.example.com, ws = true, ws.uri = /ws, ws.http-fields = Connection:keep-alive, force-vmess-aead = true, tfo = true, test-url = http://test.example.com, dont-alert-error = true, port = 6152, server-address = svr.example.com, interface-name = AirPort, back-to-default-if-nic-unavailable = true, ip.packet-tos = 2, ip.version-strategy = v4"
  }
  private var possibleParseOutput: AnyProxy {
    var expected = AnyProxy(name: "VMESS")
    expected.serverAddress = "svr.example.com"
    expected.port = 6152
    expected.kind = .vmess
    expected.username = "C51F3C92-EEF6-4506-A39F-C2D7786A50D7"
    expected.passwordReference = "password"
    expected.alpn = "h2"
    expected.authenticationRequired = true
    expected.algorithm = .aes256Gcm
    expected.obfuscation.isEnabled = true
    expected.obfuscation.strategy = .tls
    expected.obfuscation.hostname = "obfuscate.example.com"
    expected.measurement.url = .init(string: "http://test.example.com")
    expected.engress.interfaceName = "AirPort"
    expected.engress.backToDefaultIfNICUnavailable = true
    expected.engress.packetToS = 2
    expected.engress.versionStrategy = .v4
    expected.tls.isEnabled = true
    expected.tls.skipCertificateVerification = true
    expected.tls.sni = "sni.example.com"
    expected.tls.certificatePinning = "wLgBEAGmLltnXbK6pzpvPMeOCTKZ0QwrWGem6DkNf6o="
    expected.ws.isEnabled = true
    expected.ws.uri = "/ws"
    expected.ws.additionalHTTPFields = [.connection: "keep-alive"]
    expected.allowUDPRelay = true
    expected.isTFOEnabled = true
    expected.forceHTTPTunneling = true
    expected.dontAlertError = true
    return expected
  }

  @Test func formatDirectProxy() {
    var proxy = AnyProxy(name: "DIRECT")
    proxy.kind = .direct
    let formatOutput = "DIRECT = direct"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)

    proxy = base
    proxy.kind = .direct
    proxy.name = "DIRECT"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)
  }

  @Test func formatRejectProxy() {
    var proxy = AnyProxy(name: "REJECT")
    proxy.kind = .reject
    let formatOutput = "REJECT = reject"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)

    proxy = base
    proxy.kind = .reject
    proxy.name = "REJECT"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)
  }

  @Test func formatRejectTinyGIFProxy() {
    var proxy = AnyProxy(name: "REJECT-TINYGIF")
    proxy.kind = .rejectTinyGIF
    let formatOutput = "REJECT-TINYGIF = reject-tinygif"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)

    proxy = base
    proxy.kind = .rejectTinyGIF
    proxy.name = "REJECT-TINYGIF"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)
  }

  @Test func formatHTTPProxy() {
    var proxy = AnyProxy(name: "HTTP")
    proxy.kind = .http
    proxy.port = 6152
    proxy.serverAddress = "svr.example.com"
    var formatOutput = "HTTP = http, port = 6152, server-address = svr.example.com"
    // Ignore all default values.
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)

    proxy = base
    proxy.kind = .http
    proxy.name = "HTTP"
    formatOutput =
      "HTTP = http, username = username, password-reference = password, authentication-required = true, force-http-tunneling = true, test-url = http://test.example.com, dont-alert-error = true, port = 6152, server-address = svr.example.com, interface-name = AirPort, back-to-default-if-nic-unavailable = true, ip.packet-tos = 2, ip.version-strategy = v4"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)
  }

  @Test func formatHTTPSProxy() {
    var proxy = AnyProxy(name: "HTTPS")
    proxy.kind = .https
    proxy.port = 6152
    proxy.serverAddress = "svr.example.com"
    var formatOutput = "HTTPS = https, port = 6152, server-address = svr.example.com"
    // Ignore all default values.
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)

    proxy = base
    proxy.kind = .https
    proxy.name = "HTTPS"
    formatOutput =
      "HTTPS = https, username = username, password-reference = password, authentication-required = true, tls = true, tls.skip-certificate-verification = true, tls.sni = sni.example.com, tls.certificate-pinning = wLgBEAGmLltnXbK6pzpvPMeOCTKZ0QwrWGem6DkNf6o=, force-http-tunneling = true, test-url = http://test.example.com, dont-alert-error = true, port = 6152, server-address = svr.example.com, interface-name = AirPort, back-to-default-if-nic-unavailable = true, ip.packet-tos = 2, ip.version-strategy = v4"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)
  }

  @Test func formatSOCKS5Proxy() {
    var proxy = AnyProxy(name: "SOCKS5")
    proxy.kind = .socks5
    proxy.port = 6152
    proxy.serverAddress = "svr.example.com"
    var formatOutput = "SOCKS5 = socks5, port = 6152, server-address = svr.example.com"
    // Ignore all default values.
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)

    proxy = base
    proxy.kind = .socks5
    proxy.name = "SOCKS5"
    formatOutput =
      "SOCKS5 = socks5, username = username, password-reference = password, authentication-required = true, allow-udp-relay = true, tfo = true, test-url = http://test.example.com, dont-alert-error = true, port = 6152, server-address = svr.example.com, interface-name = AirPort, back-to-default-if-nic-unavailable = true, ip.packet-tos = 2, ip.version-strategy = v4"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)
  }

  @Test func formatSOCKS5OverTLSProxy() {
    var proxy = AnyProxy(name: "SOCKS5-OVER-TLS")
    proxy.kind = .socks5OverTLS
    proxy.port = 6152
    proxy.serverAddress = "svr.example.com"
    var formatOutput =
      "SOCKS5-OVER-TLS = socks5-over-tls, port = 6152, server-address = svr.example.com"
    // Ignore all default values.
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)

    proxy = base
    proxy.kind = .socks5OverTLS
    proxy.name = "SOCKS5-OVER-TLS"
    formatOutput =
      "SOCKS5-OVER-TLS = socks5-over-tls, username = username, password-reference = password, authentication-required = true, tls = true, tls.skip-certificate-verification = true, tls.sni = sni.example.com, tls.certificate-pinning = wLgBEAGmLltnXbK6pzpvPMeOCTKZ0QwrWGem6DkNf6o=, allow-udp-relay = true, tfo = true, test-url = http://test.example.com, dont-alert-error = true, port = 6152, server-address = svr.example.com, interface-name = AirPort, back-to-default-if-nic-unavailable = true, ip.packet-tos = 2, ip.version-strategy = v4"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)
  }

  @Test func formatShadowsocksProxy() {
    var proxy = AnyProxy(name: "SHADOWSOCKS")
    proxy.kind = .shadowsocks
    proxy.port = 6152
    proxy.serverAddress = "svr.example.com"
    var formatOutput = "SHADOWSOCKS = ss, port = 6152, server-address = svr.example.com"
    // Ignore all default values.
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)

    proxy = base
    proxy.kind = .shadowsocks
    proxy.name = "SHADOWSOCKS"
    formatOutput =
      "SHADOWSOCKS = ss, password-reference = password, algo = AES-256-GCM, obfs = true, obfs.strategy = 2, obfs.hostname = obfuscate.example.com, allow-udp-relay = true, tfo = true, test-url = http://test.example.com, dont-alert-error = true, port = 6152, server-address = svr.example.com, interface-name = AirPort, back-to-default-if-nic-unavailable = true, ip.packet-tos = 2, ip.version-strategy = v4"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)
  }

  @Test func formatVMESSProxy() {
    var proxy = AnyProxy(name: "VMESS")
    proxy.kind = .vmess
    proxy.port = 6152
    proxy.serverAddress = "svr.example.com"
    var formatOutput =
      "VMESS = vmess, force-vmess-aead = true, port = 6152, server-address = svr.example.com"
    // Ignore all default values.
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)

    proxy = base
    proxy.kind = .vmess
    proxy.name = "VMESS"
    proxy.username = "C51F3C92-EEF6-4506-A39F-C2D7786A50D7"
    formatOutput =
      "VMESS = vmess, username = C51F3C92-EEF6-4506-A39F-C2D7786A50D7, tls = true, tls.skip-certificate-verification = true, tls.sni = sni.example.com, tls.certificate-pinning = wLgBEAGmLltnXbK6pzpvPMeOCTKZ0QwrWGem6DkNf6o=, ws = true, ws.uri = /ws, ws.http-fields = Connection:keep-alive, force-vmess-aead = true, tfo = true, test-url = http://test.example.com, dont-alert-error = true, port = 6152, server-address = svr.example.com, interface-name = AirPort, back-to-default-if-nic-unavailable = true, ip.packet-tos = 2, ip.version-strategy = v4"
    #expect(proxy.formatted() == formatOutput)
    #expect(AnyProxy.FormatStyle().format(proxy) == formatOutput)
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  @Test(arguments: [
    AnyProxy.FormatStyle(),
    AnyProxy.FormatStyle().parseStrategy,
    AnyProxy.FormatStyle.proxy,
  ])
  func parse(_ parser: AnyProxy.FormatStyle) throws {
    let parseOutput = try parser.parse(possibleParseInput)
    #expect(parseOutput.name == possibleParseOutput.name)
    #expect(parseOutput.kind == possibleParseOutput.kind)
    #expect(parseOutput.serverAddress == possibleParseOutput.serverAddress)
    #expect(parseOutput.port == possibleParseOutput.port)
    #expect(parseOutput.username == possibleParseOutput.username)
    #expect(parseOutput.passwordReference == possibleParseOutput.passwordReference)
    #expect(parseOutput.alpn == possibleParseOutput.alpn)
    #expect(parseOutput.authenticationRequired == possibleParseOutput.authenticationRequired)
    #expect(parseOutput.algorithm == possibleParseOutput.algorithm)
    #expect(parseOutput.obfuscation.isEnabled == possibleParseOutput.obfuscation.isEnabled)
    #expect(parseOutput.obfuscation.strategy == possibleParseOutput.obfuscation.strategy)
    #expect(parseOutput.obfuscation.hostname == possibleParseOutput.obfuscation.hostname)
    #expect(parseOutput.measurement.url == possibleParseOutput.measurement.url)
    #expect(parseOutput.engress.interfaceName == possibleParseOutput.engress.interfaceName)
    #expect(
      parseOutput.engress.backToDefaultIfNICUnavailable
        == possibleParseOutput.engress.backToDefaultIfNICUnavailable
    )
    #expect(parseOutput.engress.packetToS == possibleParseOutput.engress.packetToS)
    #expect(
      parseOutput.engress.versionStrategy == possibleParseOutput.engress.versionStrategy)
    #expect(parseOutput.tls.isEnabled == possibleParseOutput.tls.isEnabled)
    #expect(
      parseOutput.tls.skipCertificateVerification
        == possibleParseOutput.tls.skipCertificateVerification)
    #expect(parseOutput.tls.sni == possibleParseOutput.tls.sni)
    #expect(parseOutput.tls.certificatePinning == possibleParseOutput.tls.certificatePinning)
    #expect(parseOutput.ws.isEnabled == possibleParseOutput.ws.isEnabled)
    #expect(parseOutput.ws.uri == possibleParseOutput.ws.uri)
    #expect(
      parseOutput.ws.additionalHTTPFields == possibleParseOutput.ws.additionalHTTPFields)
    #expect(parseOutput.allowUDPRelay == possibleParseOutput.allowUDPRelay)
    #expect(parseOutput.isTFOEnabled == possibleParseOutput.isTFOEnabled)
    #expect(parseOutput.forceHTTPTunneling == possibleParseOutput.forceHTTPTunneling)
    #expect(parseOutput.dontAlertError == possibleParseOutput.dontAlertError)
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  @Test func parseAnyProxyFromInvalidString() throws {
    let parseInput = "NotAValidProxy = abc"
    #expect(throws: CocoaError.self) {
      try formatter.parse(parseInput)
    }
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  @Test func parseAlias() throws {
    let parseInput = "DIRECT = direct"
    let parseOutput = try AnyProxy.FormatStyle().parse(parseInput)
    #expect(parseOutput.kind == .direct)
    #expect(parseOutput.name == "DIRECT")
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  @Test(arguments: [
    "HTTP = http, server-address = , port = 0",
    "HTTP = http, port = 0",
    "HTTP = http, server-address = example.com, port = ",
    "HTTP = http, server-address = example.com",
  ])
  func parseFromIncompleteString(_ parseInput: String) throws {
    #expect(throws: CocoaError.self) {
      try AnyProxy.FormatStyle().parse(parseInput)
    }
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  @Test(
    arguments: zip(
      [
        "DIRECT = direct, port = 80",
        "REJECT = reject, port = 80",
        "REJECT-TINYGIF = reject-tinygif, port = 80",
        "HTTP = http, username = username, password-reference = password, tls = true, sni = example.com, certificate-pinning = abc, should-be-ignored1 = 123, should-be-ignored2 = false, port = 443, server-address = https://example.com",
      ],
      [
        "DIRECT = direct",
        "REJECT = reject",
        "REJECT-TINYGIF = reject-tinygif",
        "HTTP = http, username = username, password-reference = password, port = 443, server-address = https://example.com",
      ]
    ))
  func ignoreUnknownFieldsWhenParsePolicies(_ parseInput: String, expected: String) async throws {
    let parseOutput = try formatter.parse(parseInput)
    var formatOuput = formatter.format(parseOutput)
    #expect(formatOuput == expected)

    formatOuput = parseOutput.formatted()
    #expect(formatOuput == expected)

    formatOuput = parseOutput.formatted(formatter)
    #expect(formatOuput == expected)
  }

  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  @Test func formatStyleConformance() {
    var proxy = AnyProxy(name: "DIRECT")
    proxy.kind = .direct
    #expect(proxy.formatted(AnyProxy.FormatStyle()) == "DIRECT = direct")
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  @Test func parseStrategyConformance() throws {
    #expect(throws: Never.self) {
      try AnyProxy("DIRECT = direct", strategy: AnyProxy.FormatStyle())
    }
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  @Test func parseableFormatStyleConformance() {
    #expect(throws: Never.self) {
      try AnyProxy.FormatStyle().parseStrategy.parse("DIRECT = direct")
    }
  }
}
