//
// See LICENSE.txt for license information
//

import Logging
import RegexBuilder

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

extension Profile {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

extension Profile.FormatStyle {

  public enum Fields: String, Sendable {
    case logLevel = "log-level"
    case dnsServers = "dns-servers"
    case exceptions
    case httpListenAddress = "http-listen-address"
    case httpListenPort = "http-listen-port"
    case socksListenAddress = "socks-listen-address"
    case socksListenPort = "socks-listen-port"
    case excludeSimpleHostnames = "exclude-simple-hostnames"
    case skipCertificateVerification = "skip-certificate-verification"
    case hostnames
    case base64EncodedP12String = "base64-encoded-p12"
    case passphrase
    case testURL = "test-url"
    case proxyTestURL = "proxy-test-url"
    case testTimeout = "test-timeout"
    case dontAlertRejectErrors = "dont-alert-reject-errors"
    case dontAllowRemoteAccess = "dont-allow-remote-access"
  }

  public func format(_ value: Profile) -> String {
    let parseInput = value
    var lines: [String] = []
    if parseInput.logLevel != .info {
      lines.append("\(Fields.logLevel.rawValue) = \(parseInput.logLevel.rawValue)")
    }
    if !parseInput.dnsSettings.servers.isEmpty {
      lines.append(
        "\(Fields.dnsServers.rawValue) = \(parseInput.dnsSettings.servers.joined(separator: ","))")
    }
    if !parseInput.exceptions.isEmpty {
      lines.append(
        "\(Fields.exceptions.rawValue) = \(parseInput.exceptions.joined(separator: ","))")
    }
    if !parseInput.httpListenAddress.isEmpty && parseInput.httpListenAddress != "127.0.0.1" {
      lines.append("\(Fields.httpListenAddress.rawValue) = \(parseInput.httpListenAddress)")
    }
    if let httpListenPort = parseInput.httpListenPort {
      lines.append("\(Fields.httpListenPort.rawValue) = \(httpListenPort)")
    }
    if !parseInput.socksListenAddress.isEmpty && parseInput.socksListenAddress != "127.0.0.1" {
      lines.append("\(Fields.socksListenAddress) = \(parseInput.socksListenAddress)")
    }
    if let socksListenPort = parseInput.socksListenPort {
      lines.append("\(Fields.socksListenPort.rawValue) = \(socksListenPort)")
    }
    if parseInput.excludeSimpleHostnames {
      lines.append(
        "\(Fields.excludeSimpleHostnames.rawValue) = \(parseInput.excludeSimpleHostnames)")
    }
    if let absoluteString = parseInput.testURL?.absoluteString, !absoluteString.isEmpty {
      lines.append("\(Fields.testURL.rawValue) = \(absoluteString)")
    }
    if let absoluteString = parseInput.proxyTestURL?.absoluteString, !absoluteString.isEmpty {
      lines.append("\(Fields.proxyTestURL.rawValue) = \(absoluteString)")
    }
    if parseInput.testTimeout != 5 {
      lines.append("\(Fields.testTimeout.rawValue) = \(parseInput.testTimeout)")
    }
    if parseInput.dontAlertRejectErrors {
      lines.append("\(Fields.dontAlertRejectErrors.rawValue) = \(parseInput.dontAlertRejectErrors)")
    }
    if parseInput.dontAllowRemoteAccess {
      lines.append("\(Fields.dontAllowRemoteAccess.rawValue) = \(parseInput.dontAllowRemoteAccess)")
    }
    if !lines.isEmpty {
      lines.insert("[General]", at: lines.startIndex)
      lines.append("")
    }

    if !parseInput.lazyProxies.isEmpty {
      lines.append(AnyProxy.sectionName)
      let sequence = parseInput.lazyProxies.lazy.filter { $0.source == .userDefined }.map {
        $0.formatted()
      }
      lines.append(contentsOf: sequence)
      lines.append("")
    }

    if !parseInput.lazyProxyGroups.isEmpty {
      lines.append(AnyProxyGroup.sectionName)
      lines.append(contentsOf: parseInput.lazyProxyGroups.map { $0.formatted() })
      lines.append("")
    }

    if !parseInput.lazyForwardingRules.isEmpty {
      lines.append(AnyForwardingRule.sectionName)
      lines.append(contentsOf: parseInput.lazyForwardingRules.map { $0.formatted() })
      lines.append("")
    }

    let startIndex = lines.endIndex
    let numberOfLines = lines.count
    if parseInput.skipCertificateVerification {
      lines.append(
        "\(Fields.skipCertificateVerification.rawValue) = \(parseInput.skipCertificateVerification)"
      )
    }
    if !parseInput.hostnames.isEmpty {
      lines.append("\(Fields.hostnames.rawValue) = \(parseInput.hostnames.joined(separator: ","))")
    }
    if !parseInput.base64EncodedP12String.isEmpty {
      lines.append(
        "\(Fields.base64EncodedP12String.rawValue) = \(parseInput.base64EncodedP12String)")
    }
    if !parseInput.passphrase.isEmpty {
      lines.append("\(Fields.passphrase.rawValue) = \(parseInput.passphrase)")
    }
    if lines.count != numberOfLines {
      lines.insert("[MitM]", at: startIndex)
      lines.append("")
    }

    if !parseInput.lazyDNSMappings.isEmpty {
      lines.append(DNSMapping.sectionName)
      lines.append(contentsOf: parseInput.lazyDNSMappings.map { $0.formatted() })
      lines.append("")
    }

    if !parseInput.lazyURLRewrites.isEmpty {
      lines.append(URLRewrite.sectionName)
      lines.append(contentsOf: parseInput.lazyURLRewrites.map { $0.formatted() })
    }

    if !parseInput.lazyHTTPFieldsRewrites.isEmpty {
      lines.append(HTTPFieldsRewrite.sectionName)
      lines.append(contentsOf: parseInput.lazyHTTPFieldsRewrites.map { $0.formatted() })
    }

    let formatOutput = lines.isEmpty ? "" : lines.joined(separator: "\n")
    return formatOutput
  }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Profile.FormatStyle: FormatStyle {
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Profile.FormatStyle {

  public func parse(_ value: String) throws -> Profile {
    var parseOutput = Profile()
    let parseInputs = value.split(separator: .newlineSequence, omittingEmptySubsequences: false)

    enum ParseProgress {
      case startParseProxies
      case startParseProxyGroups
      case startParseRules
      case startParseDNSMappings
      case startParseURLRewrites
      case startParseStubbedHTTPResponses
      case startParseHTTPFieldsRewrites
      case startParseRelaxingFields
    }
    var progress = ParseProgress.startParseRelaxingFields

    var logLevel: Substring?
    var servers: [Substring]?
    var exceptions: [Substring]?
    var httpListenAddress: Substring?
    var httpListenPort: Substring?
    var socksListenAddress: Substring?
    var socksListenPort: Substring?
    var excludeSimpleHostnames: Substring?
    var skipCertificateVerification: Substring?
    var hostnames: [Substring]?
    var base64EncodedP12String: Substring?
    var passphrase: Substring?
    var testURLString: Substring?
    var proxyTestURLString: Substring?
    var testTimeout: Substring?
    var proxies: [AnyProxy] = []
    var policyGroups: [AnyProxyGroup] = []
    var rules: [AnyForwardingRule] = []
    var dnsMappings: [DNSMapping] = []
    var urlRewrites: [URLRewrite] = []
    var stubbedHTTPResponses: [StubbedHTTPResponse] = []
    var httpFieldsRewrites: [HTTPFieldsRewrite] = []

    let text = " *= *(.*)"
    let bool = " *= *(true|false)"
    let number = " *= *([0-9]*)"

    for (index, parseInput) in parseInputs.enumerated() {
      // Index start from zero (0), but line number start from one (1).
      let line = index + 1
      guard !parseInput.isEmpty else {
        continue
      }

      let parseInput = parseInput._trimmingWhitespaces()

      if let match = parseInput.firstMatch(of: /^ *(\[.+\]) *$/) {
        switch match.1 {
        case AnyProxy.sectionName:
          progress = .startParseProxies
        case AnyProxyGroup.sectionName:
          progress = .startParseProxyGroups
        case AnyForwardingRule.sectionName:
          progress = .startParseRules
        case DNSMapping.sectionName:
          progress = .startParseDNSMappings
        case URLRewrite.sectionName:
          progress = .startParseURLRewrites
        case StubbedHTTPResponse.sectionName:
          progress = .startParseStubbedHTTPResponses
        case HTTPFieldsRewrite.sectionName:
          progress = .startParseHTTPFieldsRewrites
        default:
          progress = .startParseRelaxingFields
        }
        continue
      }

      switch progress {
      case .startParseProxies:
        let data = try AnyProxy.FormatStyle().parse(parseInput)
        proxies.append(data)
      case .startParseProxyGroups:
        let data = try AnyProxyGroup.FormatStyle().parse(parseInput)
        policyGroups.append(data)
      case .startParseRules:
        let data = try AnyForwardingRule.FormatStyle().parse(parseInput)
        rules.append(data)
      case .startParseDNSMappings:
        let data = try DNSMapping.FormatStyle().parse(parseInput)
        dnsMappings.append(data)
      case .startParseURLRewrites:
        let data = try URLRewrite.FormatStyle().parse(parseInput)
        urlRewrites.append(data)
      case .startParseStubbedHTTPResponses:
        let data = try StubbedHTTPResponse.FormatStyle().parse(parseInput)
        stubbedHTTPResponses.append(data)
      case .startParseHTTPFieldsRewrites:
        let data = try HTTPFieldsRewrite.FormatStyle().parse(parseInput)
        httpFieldsRewrites.append(data)
      case .startParseRelaxingFields:
        if logLevel == nil {
          let pattern = /^ *log-level *= *(trace|debug|info|notice|warning|error|critical) *$/
          logLevel = parseInput.firstMatch(of: pattern)?.1
          if let logLevel {
            parseOutput.logLevel =
              .init(rawValue: logLevel._trimmingWhitespaces()) ?? .info
            continue
          }
        }

        var pattern: Regex<(Substring, Substring)>

        if servers == nil {
          pattern = try .init("^ *\(Fields.dnsServers.rawValue)\(text)")
          servers = parseInput.firstMatch(of: pattern)?.1.split(separator: ",")
          if let servers {
            parseOutput.dnsSettings.servers = servers.map {
              $0._trimmingWhitespaces()
            }
            continue
          }
        }

        if exceptions == nil {
          pattern = try .init("^ *\(Fields.exceptions.rawValue)\(text)")
          exceptions = parseInput.firstMatch(of: pattern)?.1.split(separator: ",")
          if let exceptions {
            parseOutput.exceptions = exceptions.map { $0._trimmingWhitespaces() }
            continue
          }
        }

        if httpListenAddress == nil {
          pattern = try .init("^ *\(Fields.httpListenAddress.rawValue)\(text)")
          httpListenAddress = parseInput.firstMatch(of: pattern)?.1
          if let httpListenAddress {
            parseOutput.httpListenAddress = httpListenAddress._trimmingWhitespaces()
            continue
          }
        }

        if httpListenPort == nil {
          pattern = try .init("^ *\(Fields.httpListenPort.rawValue)\(number)")
          httpListenPort = parseInput.firstMatch(of: pattern)?.1
          if let httpListenPort {
            guard !httpListenPort.isEmpty else {
              let errorStr =
                "Cannot parse \(Fields.httpListenPort) at line #\(line) \(parseInput). String should adhere to the preferred format, such as \"\(Fields.httpListenPort.rawValue) = 6152\"."
              throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
            }

            parseOutput.httpListenPort = Int(httpListenPort)
            continue
          }
        }

        if socksListenAddress == nil {
          pattern = try .init("^ *\(Fields.socksListenAddress.rawValue)\(text)")
          socksListenAddress = parseInput.firstMatch(of: pattern)?.1
          if let socksListenAddress {
            parseOutput.socksListenAddress = socksListenAddress._trimmingWhitespaces()
            continue
          }
        }

        if socksListenPort == nil {
          pattern = try .init("^ *\(Fields.socksListenPort.rawValue)\(number)")
          socksListenPort = parseInput.firstMatch(of: pattern)?.1
          if let socksListenPort {
            guard !socksListenPort.isEmpty else {
              let errorStr =
                "Cannot parse \(Fields.socksListenPort) at line #\(line) \(parseInput). String should adhere to the preferred format, such as \"\(Fields.socksListenPort.rawValue) = 6153\"."
              throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
            }
            parseOutput.socksListenPort = Int(socksListenPort)
            continue
          }
        }

        if excludeSimpleHostnames == nil {
          pattern = try .init("^ *\(Fields.excludeSimpleHostnames.rawValue)\(text)")
          excludeSimpleHostnames = parseInput.firstMatch(of: pattern)?.1
          if let excludeSimpleHostnames {
            parseOutput.excludeSimpleHostnames = excludeSimpleHostnames == "true"
            continue
          }
        }

        if skipCertificateVerification == nil {
          pattern = try .init("^ *\(Fields.skipCertificateVerification.rawValue)\(bool)")
          skipCertificateVerification = parseInput.firstMatch(of: pattern)?.1
          if let skipCertificateVerification {
            parseOutput.skipCertificateVerification = skipCertificateVerification == "true"
            continue
          }
        }

        if hostnames == nil {
          pattern = try .init("^ *\(Fields.hostnames.rawValue)\(text)")
          hostnames = parseInput.firstMatch(of: pattern)?.1.split(separator: ",")
          if let hostnames {
            parseOutput.hostnames = hostnames.map { $0._trimmingWhitespaces() }
            continue
          }
        }

        if base64EncodedP12String == nil {
          pattern = try .init("^ *\(Fields.base64EncodedP12String.rawValue)\(text)")
          base64EncodedP12String = parseInput.firstMatch(of: pattern)?.1
          if let base64EncodedP12String {
            parseOutput.base64EncodedP12String = base64EncodedP12String._trimmingWhitespaces()
            continue
          }
        }

        if passphrase == nil {
          pattern = try .init("^ *\(Fields.passphrase.rawValue)\(text)")
          passphrase = parseInput.firstMatch(of: pattern)?.1
          if let passphrase {
            parseOutput.passphrase = passphrase._trimmingWhitespaces()
            continue
          }
        }

        if testURLString == nil {
          pattern = try .init("^ *\(Fields.testURL.rawValue)\(text)")
          testURLString = parseInput.firstMatch(of: pattern)?.1
          if let testURLString {
            parseOutput.testURL = URL(string: testURLString._trimmingWhitespaces())
            continue
          }
        }

        if proxyTestURLString == nil {
          pattern = try .init("^ *\(Fields.proxyTestURL.rawValue)\(text)")
          proxyTestURLString = parseInput.firstMatch(of: pattern)?.1
          if let proxyTestURLString {
            parseOutput.proxyTestURL = URL(
              string: proxyTestURLString._trimmingWhitespaces())
            continue
          }
        }

        if testTimeout == nil {
          pattern = try .init("^ *\(Fields.testTimeout.rawValue)\(text)")
          testTimeout = parseInput.firstMatch(of: pattern)?.1
          if let testTimeout {
            guard let timeout = TimeInterval(testTimeout) else {
              let errorStr =
                "Cannot parse \(Fields.testTimeout) at line #\(line) \(parseInput). String should adhere to the preferred format, such as \"\(Fields.testTimeout.rawValue) = 5.0\"."
              throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
            }
            parseOutput.testTimeout = timeout
            continue
          }
        }
      }
    }
    parseOutput.lazyProxies = proxies
    parseOutput.lazyProxyGroups = policyGroups
    parseOutput.lazyForwardingRules = rules
    parseOutput.lazyDNSMappings = dnsMappings
    parseOutput.lazyURLRewrites = urlRewrites
    parseOutput.lazyStubbedHTTPResponses = stubbedHTTPResponses
    parseOutput.lazyHTTPFieldsRewrites = httpFieldsRewrites
    return parseOutput
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Profile.FormatStyle: ParseStrategy {
}

extension Profile.FormatStyle {
  public var parseStrategy: Profile.FormatStyle {
    self
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Profile.FormatStyle: ParseableFormatStyle {
}

extension Profile.FormatStyle: Codable, Hashable {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension FormatStyle where Self == Profile.FormatStyle {
  public static var profile: Self { .init() }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ParseStrategy where Self == Profile.FormatStyle {
  @_disfavoredOverload
  public static var profile: Self { .init() }
}

extension Profile {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == Profile {
      return v.format(self)
    }
  #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == Profile {
      return v.format(self)
    }
  #endif

  public func formatted() -> String {
    FormatStyle().format(self)
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
