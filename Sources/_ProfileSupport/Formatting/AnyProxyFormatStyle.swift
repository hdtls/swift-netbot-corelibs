//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import HTTPTypes

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension AnyProxy {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

@available(SwiftStdlib 5.3, *)
extension AnyProxy.FormatStyle {

  private enum Fields: String {
    case username
    case passwordReference = "password-reference"
    case authenticationRequired = "authentication-required"
    case forceHTTPTunneling = "force-http-tunneling"
    case alpn
    case tls
    case tlsSkipCertVerification = "tls.skip-certificate-verification"
    case tlsSNI = "tls.sni"
    case tlsCertificatePinning = "tls.certificate-pinning"
    case allowUDPRelay = "allow-udp-relay"
    case tfo
    case algo
    case obfs
    case obfsStrategy = "obfs.strategy"
    case obfsHostname = "obfs.hostname"
    case ws
    case wsURI = "ws.uri"
    case wsFields = "ws.http-fields"
    case forceVMESSAEAD = "force-vmess-aead"
    case testURL = "test-url"
    case dontAlertError = "dont-alert-error"
    case port
    case serverAddress = "server-address"
    case interfaceName = "interface-name"
    case backToDefaultIfNICUnavailable = "back-to-default-if-nic-unavailable"
    case ipPacketToS = "ip.packet-tos"
    case ipVersionStrategy = "ip.version-strategy"
  }

  public func format(_ value: AnyProxy) -> String {
    var formatOutput = "\(value.name) = \(value.kind.rawValue)"
    switch value.kind {
    case .direct, .reject:
      return formatOutput
    case .rejectTinyGIF:
      return formatOutput
    case .http:
      if !value.username._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.username.rawValue) = \(value.username)"
      }
      if !value.passwordReference._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.passwordReference.rawValue) = \(value.passwordReference)"
      }
      if value.authenticationRequired {
        formatOutput +=
          ", \(Fields.authenticationRequired.rawValue) = \(value.authenticationRequired)"
      }
      if value.forceHTTPTunneling {
        formatOutput += ", \(Fields.forceHTTPTunneling.rawValue) = \(value.forceHTTPTunneling)"
      }
    case .https:
      if !value.username._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.username.rawValue) = \(value.username)"
      }
      if !value.passwordReference._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.passwordReference.rawValue) = \(value.passwordReference)"
      }
      if value.authenticationRequired {
        formatOutput +=
          ", \(Fields.authenticationRequired.rawValue) = \(value.authenticationRequired)"
      }
      if value.tls.isEnabled {
        formatOutput += ", \(Fields.tls.rawValue) = \(value.tls.isEnabled)"
      }
      if value.tls.skipCertificateVerification {
        formatOutput +=
          ", \(Fields.tlsSkipCertVerification.rawValue) = \(value.tls.skipCertificateVerification)"
      }
      if !value.tls.sni._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.tlsSNI.rawValue) = \(value.tls.sni)"
      }
      if !value.tls.certificatePinning._trimmingWhitespaces().isEmpty {
        formatOutput +=
          ", \(Fields.tlsCertificatePinning.rawValue) = \(value.tls.certificatePinning)"
      }
      if value.forceHTTPTunneling {
        formatOutput += ", \(Fields.forceHTTPTunneling.rawValue) = \(value.forceHTTPTunneling)"
      }
    case .socks5:
      if !value.username._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.username.rawValue) = \(value.username)"
      }
      if !value.passwordReference._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.passwordReference.rawValue) = \(value.passwordReference)"
      }
      if value.authenticationRequired {
        formatOutput +=
          ", \(Fields.authenticationRequired.rawValue) = \(value.authenticationRequired)"
      }
      if value.allowUDPRelay {
        formatOutput += ", \(Fields.allowUDPRelay.rawValue) = \(value.allowUDPRelay)"
      }
      if value.isTFOEnabled {
        formatOutput += ", \(Fields.tfo.rawValue) = \(value.isTFOEnabled)"
      }
    case .socks5OverTLS:
      if !value.username._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.username.rawValue) = \(value.username)"
      }
      if !value.passwordReference._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.passwordReference.rawValue) = \(value.passwordReference)"
      }
      if value.authenticationRequired {
        formatOutput +=
          ", \(Fields.authenticationRequired.rawValue) = \(value.authenticationRequired)"
      }
      if value.tls.isEnabled {
        formatOutput += ", \(Fields.tls.rawValue) = \(value.tls.isEnabled)"
      }
      if value.tls.skipCertificateVerification {
        formatOutput +=
          ", \(Fields.tlsSkipCertVerification.rawValue) = \(value.tls.skipCertificateVerification)"
      }
      if !value.tls.sni._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.tlsSNI.rawValue) = \(value.tls.sni)"
      }
      if !value.tls.certificatePinning._trimmingWhitespaces().isEmpty {
        formatOutput +=
          ", \(Fields.tlsCertificatePinning.rawValue) = \(value.tls.certificatePinning)"
      }
      if value.allowUDPRelay {
        formatOutput += ", \(Fields.allowUDPRelay.rawValue) = \(value.allowUDPRelay)"
      }
      if value.isTFOEnabled {
        formatOutput += ", \(Fields.tfo.rawValue) = \(value.isTFOEnabled)"
      }
    case .shadowsocks:
      if !value.passwordReference._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.passwordReference.rawValue) = \(value.passwordReference)"
      }
      if value.algorithm != .aes128Gcm {
        formatOutput += ", \(Fields.algo.rawValue) = \(value.algorithm.rawValue)"
      }
      if value.obfuscation.isEnabled {
        formatOutput += ", \(Fields.obfs.rawValue) = \(value.obfuscation.isEnabled)"
      }
      if value.obfuscation.strategy != .http {
        formatOutput += ", \(Fields.obfsStrategy.rawValue) = \(value.obfuscation.strategy.rawValue)"
      }
      if !value.obfuscation.hostname._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.obfsHostname.rawValue) = \(value.obfuscation.hostname)"
      }
      if value.allowUDPRelay {
        formatOutput += ", \(Fields.allowUDPRelay.rawValue) = \(value.allowUDPRelay)"
      }
      if value.isTFOEnabled {
        formatOutput += ", \(Fields.tfo.rawValue) = \(value.isTFOEnabled)"
      }
    case .vmess:
      if !value.username._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.username.rawValue) = \(value.username)"
      }
      if value.tls.isEnabled {
        formatOutput += ", \(Fields.tls.rawValue) = \(value.tls.isEnabled)"
      }
      if value.tls.skipCertificateVerification {
        formatOutput +=
          ", \(Fields.tlsSkipCertVerification.rawValue) = \(value.tls.skipCertificateVerification)"
      }
      if !value.tls.sni._trimmingWhitespaces().isEmpty {
        formatOutput += ", \(Fields.tlsSNI.rawValue) = \(value.tls.sni)"
      }
      if !value.tls.certificatePinning._trimmingWhitespaces().isEmpty {
        formatOutput +=
          ", \(Fields.tlsCertificatePinning.rawValue) = \(value.tls.certificatePinning)"
      }
      if value.ws.isEnabled {
        formatOutput += ", \(Fields.ws.rawValue) = \(value.ws.isEnabled)"
      }
      if value.ws.uri._trimmingWhitespaces() != "/" {
        formatOutput += ", \(Fields.wsURI.rawValue) = \(value.ws.uri)"
      }
      if let additionalHTTPFields = value.ws.additionalHTTPFields {
        formatOutput +=
          ", \(Fields.wsFields.rawValue) = \(additionalHTTPFields.formatted())"
      }
      formatOutput += ", \(Fields.forceVMESSAEAD.rawValue) = true"
      if value.isTFOEnabled {
        formatOutput += ", \(Fields.tfo.rawValue) = \(value.isTFOEnabled)"
      }
    }
    if let testURL = value.measurement.url {
      formatOutput += ", \(Fields.testURL.rawValue) = \(testURL.absoluteString)"
    }
    if value.dontAlertError {
      formatOutput += ", \(Fields.dontAlertError.rawValue) = \(value.dontAlertError)"
    }
    formatOutput += ", \(Fields.port.rawValue) = \(value.port)"
    formatOutput += ", \(Fields.serverAddress.rawValue) = \(value.serverAddress)"
    if !value.engress.interfaceName._trimmingWhitespaces().isEmpty {
      formatOutput += ", \(Fields.interfaceName.rawValue) = \(value.engress.interfaceName)"
    }
    if value.engress.backToDefaultIfNICUnavailable {
      formatOutput +=
        ", \(Fields.backToDefaultIfNICUnavailable.rawValue) = \(value.engress.backToDefaultIfNICUnavailable)"
    }
    if value.engress.packetToS != 0 {
      formatOutput += ", \(Fields.ipPacketToS.rawValue) = \(value.engress.packetToS)"
    }
    if value.engress.versionStrategy != .dual {
      formatOutput +=
        ", \(Fields.ipVersionStrategy.rawValue) = \(value.engress.versionStrategy.rawValue)"
    }
    return formatOutput
  }
}

@available(SwiftStdlib 5.5, *)
extension AnyProxy.FormatStyle: FormatStyle {
}

@available(SwiftStdlib 5.3, *)
extension AnyProxy.FormatStyle {

  public func parse(_ value: String) throws -> AnyProxy {
    if #available(SwiftStdlib 5.7, *) {
      try _parse(value)
    } else {
      try _parse0(value)
    }
  }

  @available(SwiftStdlib 5.7, *)
  func _parse(_ value: String) throws -> AnyProxy {
    var parseOutput = ParseOutput()

    guard let match = value.firstMatch(of: AnyProxy.regex) else {
      var example = AnyProxy()
      example.kind = .vmess
      example.serverAddress = "svr-example.com"
      example.port = 6152
      example.username = "username"
      example.passwordReference = "password"
      example.alpn = "h2"
      example.authenticationRequired = true
      example.algorithm = .aes256Gcm
      example.obfuscation = .init(
        isEnabled: true, strategy: .tls, hostname: "obfuscate-example.com")
      example.measurement.url = URL(string: "http://test-example.com")
      example.engress.interfaceName = "AirPort"
      example.engress.backToDefaultIfNICUnavailable = true
      example.engress.packetToS = 2
      example.engress.versionStrategy = .v4
      example.tls.isEnabled = true
      example.tls.skipCertificateVerification = true
      example.tls.sni = "sni-example.com"
      example.tls.certificatePinning = "wLgBEAGmLltnXbK6pzpvPMeOCTKZ0QwrWGem6DkNf6o="
      example.ws = .init()
      example.ws.isEnabled = true
      example.ws.uri = "/ws"
      example.ws.additionalHTTPFields = [.connection: "keep-alive"]
      example.allowUDPRelay = true
      example.isTFOEnabled = true
      example.forceHTTPTunneling = true
      example.dontAlertError = true
      let exampleFormattedString = AnyProxy.FormatStyle().format(example)
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }

    let name = match.1._trimmingWhitespaces()
    let type = match.2
    let line = match.3 ?? ""

    guard type.isProxyable else {
      parseOutput.name = name
      parseOutput.kind = type
      return parseOutput
    }

    let text = " *= *([^,]+)"
    let bool = " *= *(true|false)"
    let number = " *= *([0-9]+)"

    var pattern = try Regex<(Substring, Substring)>("\(Fields.port.rawValue)\(number)")
    //    var pattern = /port *= *([0-9]+)/
    let portString = line.firstMatch(of: pattern)?.1 ?? ""
    guard let port = Int(portString) else {
      let errorStr = "Cannot parse \(value). Missing \"port\" field."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }

    pattern = try .init("\(Fields.serverAddress.rawValue)\(text)")
    //    pattern = /server-address *= *([^,]+)/
    guard let serverAddress = line.firstMatch(of: pattern)?.1._trimmingWhitespaces(),
      !serverAddress.isEmpty
    else {
      let errorStr = "Cannot parse \(value). Missing \"\(Fields.serverAddress.rawValue)\" field."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }

    pattern = try .init("\(Fields.username.rawValue)\(text)")
    //    pattern = /username *= *([^,]+)/
    let username = line.firstMatch(of: pattern)?.1 ?? ""

    pattern = try .init("\(Fields.passwordReference.rawValue)\(text)")
    //    pattern = /password-reference *= *([^,]+)/
    let passwordReference = line.firstMatch(of: pattern)?.1 ?? ""

    pattern = try .init("\(Fields.alpn.rawValue)\(text)")
    //    pattern = /alpn *= *([^,]+)/
    let alpn = line.firstMatch(of: pattern)?.1 ?? ""

    pattern = try .init("\(Fields.authenticationRequired.rawValue)\(bool)")
    //    pattern = /authentication-required *= *(true|false)/
    let authenticationRequired = line.firstMatch(of: pattern)?.1 == "true"

    pattern = try .init(
      "\(Fields.algo.rawValue) *= *(?i)(aes-128-gcm|aes-256-gcm|chacha20-poly1305)")
    //    pattern = /algo *= *(aes-128-gcm|aes-256-gcm|chacha20-poly1305)/
    let algorithmString =
      line.firstMatch(of: pattern)?.1._trimmingWhitespaces() ?? "aes-128-gcm"
    let algorithm = Algorithm(rawValue: algorithmString) ?? .aes128Gcm

    pattern = try .init("\(Fields.obfs.rawValue)\(bool)")
    //    pattern = /obfs *= *(true|false)/
    let obfs = line.firstMatch(of: pattern)?.1 == "true"

    pattern = try .init("\(Fields.obfsStrategy.rawValue)\(number)")
    //    pattern = /obfs-strategy *= *([0-9]+)/
    let obfsStrategyString =
      line.firstMatch(of: pattern)?.1._trimmingWhitespaces() ?? "1"
    let obfsStrategy = AnyProxy.Obfuscation.Strategy(rawValue: Int(obfsStrategyString) ?? 1)

    pattern = try .init("\(Fields.obfsHostname.rawValue)\(text)")
    //    pattern = /obfs-hostname *= *([^,]+)/
    let obfsHostname = line.firstMatch(of: pattern)?.1 ?? ""

    pattern = try .init("\(Fields.testURL.rawValue)\(text)")
    //    pattern = /test-url *= *([^,]+)/
    let testURLString = line.firstMatch(of: pattern)?.1 ?? ""
    let testURL =
      testURLString._trimmingWhitespaces().isEmpty
      ? nil : URL(string: testURLString._trimmingWhitespaces())

    pattern = try .init("\(Fields.interfaceName.rawValue)\(text)")
    //    pattern = /interface-name *= *([^,]+)/
    let interfaceName = line.firstMatch(of: pattern)?.1 ?? ""

    pattern = try .init("\(Fields.backToDefaultIfNICUnavailable.rawValue)\(bool)")
    //    pattern = /back-to-default-if-nic-unavailable *= *(true|false)/
    let backToDefaultIfNICUnavailable = line.firstMatch(of: pattern)?.1 == "true"

    pattern = try .init("\(Fields.ipPacketToS.rawValue)\(text)")
    //    pattern = /ip-packet-tos *= *([^,]+)/
    let ipPacketToS = line.firstMatch(of: pattern)?.1 ?? "0"

    pattern = try .init("\(Fields.ipVersionStrategy.rawValue)\(text)")
    //    pattern = /ip-version-strategy *= *([^,]+)/
    let ipVersionStrategyString = line.firstMatch(of: pattern)?.1 ?? ""
    let ipVersionStrategy =
      AnyProxy.Engress.VersionStrategy(rawValue: String(ipVersionStrategyString)) ?? .dual

    pattern = try .init("\(Fields.ws.rawValue)\(bool)")
    //    pattern = /ws *= *(true|false)/
    let ws = line.firstMatch(of: pattern)?.1 == "true"

    pattern = try .init("\(Fields.wsURI.rawValue)\(text)")
    //    pattern = /ws-ds *= *([^,]+)/
    let wsURI = line.firstMatch(of: pattern)?.1 ?? "/"

    pattern = try .init("\(Fields.wsFields.rawValue)\(text)")
    var additionHTTPFields: HTTPFields?
    if let parseInput = line.firstMatch(of: pattern)?.1._trimmingWhitespaces(),
      !parseInput.isEmpty
    {
      additionHTTPFields = try HTTPFields.FormatStyle().parse(parseInput)
    }

    pattern = try .init("\(Fields.tls.rawValue)\(bool)")
    //    pattern = /tls *= *(true|false)/
    var tls = line.firstMatch(of: pattern)?.1 == "true"
    // Ensure TLS is enabled when parse HTTPS and SOCKS5 over TLS.
    tls = type == .https || type == .socks5OverTLS ? true : tls

    pattern = try .init("\(Fields.tlsSkipCertVerification.rawValue)\(bool)")
    //    pattern = /tls-skip-cert-verification *= *(true|false)/
    let skipCertVerification = line.firstMatch(of: pattern)?.1 == "true"

    pattern = try .init("\(Fields.tlsSNI.rawValue)\(text)")
    //    pattern = /tls-sni *= *([^,]+)/
    let sni = line.firstMatch(of: pattern)?.1 ?? ""

    pattern = try .init("\(Fields.tlsCertificatePinning.rawValue)\(text)")
    //    pattern = /tls-certificate-pinning *= *([^,]+)/
    let certificatePinning = line.firstMatch(of: pattern)?.1 ?? ""

    pattern = try .init("\(Fields.allowUDPRelay.rawValue)\(bool)")
    //    pattern = /allow-udp-relay *= *(true|false)/
    let allowUDPRelay = line.firstMatch(of: pattern)?.1 == "true"

    pattern = try .init("\(Fields.tfo.rawValue)\(bool)")
    //    pattern = /tfo *= *(true|false)/
    let isTFOEnabled = line.firstMatch(of: pattern)?.1 == "true"

    pattern = try .init("\(Fields.forceHTTPTunneling.rawValue)\(bool)")
    //    pattern = /force-http-tunneling *= *(true|false)/
    let forceHTTPTunneling = line.firstMatch(of: pattern)?.1 == "true"

    pattern = try .init("\(Fields.dontAlertError.rawValue)\(bool)")
    //    pattern = /dont-alert-error *= *(true|false)/
    let dontAlertError = line.firstMatch(of: pattern)?.1 == "true"

    parseOutput.name = name
    parseOutput.kind = type
    parseOutput.serverAddress = serverAddress._trimmingWhitespaces()
    parseOutput.port = port
    parseOutput.username = username._trimmingWhitespaces()
    parseOutput.passwordReference = passwordReference._trimmingWhitespaces()
    parseOutput.alpn = alpn._trimmingWhitespaces()
    parseOutput.authenticationRequired = authenticationRequired
    parseOutput.algorithm = algorithm
    parseOutput.obfuscation.isEnabled = obfs
    parseOutput.obfuscation.strategy = obfsStrategy
    parseOutput.obfuscation.hostname = obfsHostname._trimmingWhitespaces()
    // swift 6.0 initialize URL with empty string is not nil
    parseOutput.measurement.url = testURL
    parseOutput.engress.interfaceName = interfaceName._trimmingWhitespaces()
    parseOutput.engress.backToDefaultIfNICUnavailable = backToDefaultIfNICUnavailable
    parseOutput.engress.packetToS = UInt8(ipPacketToS._trimmingWhitespaces()) ?? 0
    parseOutput.engress.versionStrategy = ipVersionStrategy
    parseOutput.tls.isEnabled = tls
    parseOutput.tls.skipCertificateVerification = skipCertVerification
    parseOutput.tls.sni = sni._trimmingWhitespaces()
    parseOutput.tls.certificatePinning = certificatePinning._trimmingWhitespaces()
    parseOutput.ws.uri = wsURI._trimmingWhitespaces()
    parseOutput.ws.isEnabled = ws
    parseOutput.ws.additionalHTTPFields = additionHTTPFields
    parseOutput.allowUDPRelay = allowUDPRelay
    parseOutput.isTFOEnabled = isTFOEnabled
    parseOutput.forceHTTPTunneling = forceHTTPTunneling
    parseOutput.dontAlertError = dontAlertError

    return parseOutput
  }

  func _parse0(_ value: String) throws -> AnyProxy {
    // TODO: Parse AnyProxy
    fatalError("Not implemented")
  }
}

@available(SwiftStdlib 5.5, *)
extension AnyProxy.FormatStyle: ParseStrategy {
}

@available(SwiftStdlib 5.3, *)
extension AnyProxy.FormatStyle {
  public var parseStrategy: AnyProxy.FormatStyle {
    self
  }
}

@available(SwiftStdlib 5.5, *)
extension AnyProxy.FormatStyle: ParseableFormatStyle {
}

@available(SwiftStdlib 5.3, *)
extension AnyProxy.FormatStyle: Codable, Hashable {}

@available(SwiftStdlib 5.5, *)
extension FormatStyle where Self == AnyProxy.FormatStyle {
  public static var proxy: Self { .init() }
}

@available(SwiftStdlib 5.5, *)
extension ParseableFormatStyle where Self == AnyProxy.FormatStyle {
  public static var proxy: Self { .init() }
}

@available(SwiftStdlib 5.5, *)
extension ParseStrategy where Self == AnyProxy.FormatStyle {
  @_disfavoredOverload
  public static var proxy: Self { .init() }
}

@available(SwiftStdlib 5.3, *)
extension AnyProxy {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == AnyProxy {
      return v.format(self)
    }
  #else
    @available(SwiftStdlib 5.5, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == AnyProxy {
      v.format(self)
    }
  #endif

  /// Formats `self`.
  /// - Returns: A formatted string to describe the policy, such as "DIRECT = direct".
  public func formatted() -> String {
    FormatStyle().format(self)
  }

  @available(SwiftStdlib 5.5, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
