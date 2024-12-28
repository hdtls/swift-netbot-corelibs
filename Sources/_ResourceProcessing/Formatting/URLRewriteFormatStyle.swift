//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import FoundationEssentials
#else
  public import Foundation
#endif

extension URLRewrite {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

extension URLRewrite.FormatStyle {
  public func format(_ value: URLRewrite) -> String {
    var formatOutput = value.isEnabled ? value.type.rawValue : "# \(value.type.rawValue)"
    formatOutput += "\(URLRewrite.delimiter) \(value.pattern)"
    formatOutput += "\(URLRewrite.delimiter) \(value.destination)"
    return formatOutput
  }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension URLRewrite.FormatStyle: FormatStyle {
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension URLRewrite.FormatStyle {
  public func parse(_ value: String) throws -> URLRewrite {
    let parseInput = value
    let matches = parseInput.matches(of: URLRewrite.regex)
    guard let firstMatch = matches.first else {
      var example = URLRewrite()
      example.type = .found
      example.pattern = "(?:http://)swift.org"
      example.destination = "https://swift.org"
      let exampleFormattedString = example.formatted()
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }
    var parseOutput = URLRewrite()
    parseOutput.isEnabled = firstMatch.1
    parseOutput.type = firstMatch.2
    parseOutput.pattern = firstMatch.3._trimmingWhitespaces()
    parseOutput.destination = firstMatch.4._trimmingWhitespaces()
    return parseOutput
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension URLRewrite.FormatStyle: ParseStrategy {
}

extension URLRewrite.FormatStyle {
  public var parseStrategy: URLRewrite.FormatStyle {
    self
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension URLRewrite.FormatStyle: ParseableFormatStyle {
}

extension URLRewrite.FormatStyle: Codable, Hashable {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension FormatStyle where Self == URLRewrite.FormatStyle {
  public static var urlRewrite: Self { .init() }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ParseStrategy where Self == URLRewrite.FormatStyle {
  @_disfavoredOverload
  public static var urlRewrite: Self { .init() }
}

extension URLRewrite {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == URLRewrite {
      return v.format(self)
    }
  #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == URLRewrite {
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
