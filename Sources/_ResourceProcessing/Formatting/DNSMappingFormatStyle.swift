//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import FoundationEssentials
#else
  public import Foundation
#endif

extension DNSMapping {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

extension DNSMapping.FormatStyle {
  public func format(_ value: DNSMapping) -> String {
    var formatOutput = value.isEnabled ? value.domainName : "# \(value.domainName)"
    switch value.kind {
    case .mapping, .cname:
      formatOutput += " = \(value.value)"
    case .dns:
      formatOutput += " = server:\(value.value)"
    }
    return formatOutput
  }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension DNSMapping.FormatStyle: FormatStyle {
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension DNSMapping.FormatStyle {
  public func parse(_ value: String) throws -> DNSMapping {
    let parseInput = value
    let matches = parseInput.matches(of: DNSMapping.regex)
    let cname = matches.first?.3.1
    guard let firstMatch = matches.first, let cname, !cname.contains(/\?|=/) else {
      let example = DNSMapping(domainName: "*.taobao.com", value: "223.6.6.6")
      let exampleFormattedString = DNSMapping.FormatStyle().format(example)
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }
    var parseOutput = DNSMapping()
    parseOutput.isEnabled = firstMatch.1
    parseOutput.kind = firstMatch.3.0
    parseOutput.domainName = firstMatch.2._trimmingWhitespaces()
    parseOutput.value = firstMatch.3.1._trimmingWhitespaces()
    return parseOutput
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension DNSMapping.FormatStyle: ParseStrategy {
}

extension DNSMapping.FormatStyle {
  public var parseStrategy: DNSMapping.FormatStyle {
    self
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension DNSMapping.FormatStyle: ParseableFormatStyle {
}

extension DNSMapping.FormatStyle: Codable, Hashable {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension FormatStyle where Self == DNSMapping.FormatStyle {
  public static var dnsMapping: Self { .init() }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ParseStrategy where Self == DNSMapping.FormatStyle {
  @_disfavoredOverload
  public static var dnsMapping: Self { .init() }
}

extension DNSMapping {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == DNSMapping {
      return v.format(self)
    }
  #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == DNSMapping {
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
