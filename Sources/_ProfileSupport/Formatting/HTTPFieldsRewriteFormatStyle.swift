//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

extension HTTPFieldsRewrite {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

extension HTTPFieldsRewrite.FormatStyle {
  public func format(_ formatInput: HTTPFieldsRewrite) -> String {
    var formatOutput =
      formatInput.isEnabled ? formatInput.direction.rawValue : "# \(formatInput.direction.rawValue)"
    formatOutput += "\(HTTPFieldsRewrite.delimiter)\(formatInput.pattern)"
    formatOutput += "\(HTTPFieldsRewrite.delimiter)\(formatInput.action)"
    formatOutput += "\(HTTPFieldsRewrite.delimiter)\(formatInput.name)"
    switch formatInput.action {
    case .add:
      formatOutput += "\(HTTPFieldsRewrite.delimiter)\(formatInput.value)"
    case .remove:
      formatOutput += "\(HTTPFieldsRewrite.delimiter)\(formatInput.value)"
    case .replace:
      if formatInput.replacement.isEmpty {
        formatOutput += "\(HTTPFieldsRewrite.delimiter)\(formatInput.value)"
      } else {
        formatOutput +=
          "\(HTTPFieldsRewrite.delimiter)\(formatInput.value)\(HTTPFieldsRewrite.delimiter)\(formatInput.replacement)"
      }
    }
    return formatOutput
  }
}

@available(SwiftStdlib 5.5, *)
extension HTTPFieldsRewrite.FormatStyle: FormatStyle {
}

extension HTTPFieldsRewrite.FormatStyle {

  @available(SwiftStdlib 5.7, *)
  public func parse(_ value: String) throws -> HTTPFieldsRewrite {
    let parseInput = value
    let matches = parseInput.matches(of: HTTPFieldsRewrite.regex)
    guard let firstMatch = matches.first else {
      var example = HTTPFieldsRewrite()
      example.direction = .request
      example.pattern = "(?:https://)example.org"
      example.action = .add
      example.name = "Proxy-Connection"
      example.value = "keep-alive"
      let exampleFormattedString = HTTPFieldsRewrite.FormatStyle().format(HTTPFieldsRewrite())
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }
    var parseOutput = HTTPFieldsRewrite()
    parseOutput.isEnabled = firstMatch.1
    parseOutput.direction = firstMatch.2
    parseOutput.pattern = firstMatch.3._trimmingWhitespaces()
    parseOutput.action = firstMatch.4
    parseOutput.name = firstMatch.5._trimmingWhitespaces()

    switch firstMatch.4 {
    case .add:
      parseOutput.value = firstMatch.6?._trimmingWhitespaces() ?? ""
    case .remove:
      break
    case .replace:
      if let value = firstMatch.7 {
        parseOutput.replacement = value._trimmingWhitespaces()
        parseOutput.value = firstMatch.6?._trimmingWhitespaces() ?? ""
      } else {
        parseOutput.value = ""
        parseOutput.replacement = firstMatch.6?._trimmingWhitespaces() ?? ""
      }
    }
    return parseOutput
  }
}

@available(SwiftStdlib 5.7, *)
extension HTTPFieldsRewrite.FormatStyle: ParseStrategy {
}

extension HTTPFieldsRewrite.FormatStyle {
  public var parseStrategy: HTTPFieldsRewrite.FormatStyle {
    self
  }
}

@available(SwiftStdlib 5.7, *)
extension HTTPFieldsRewrite.FormatStyle: ParseableFormatStyle {
}

extension HTTPFieldsRewrite.FormatStyle: Codable, Hashable {}

@available(SwiftStdlib 5.5, *)
extension FormatStyle where Self == HTTPFieldsRewrite.FormatStyle {
  public static var httpFieldsRewrite: Self { .init() }
}

@available(SwiftStdlib 5.7, *)
extension ParseStrategy where Self == HTTPFieldsRewrite.FormatStyle {
  @_disfavoredOverload
  public static var httpFieldsRewrite: Self { .init() }
}

extension HTTPFieldsRewrite {
  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == HTTPFieldsRewrite {
      return v.format(self)
    }
  #else
    @available(SwiftStdlib 5.5, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == HTTPFieldsRewrite {
      return v.format(self)
    }
  #endif

  public func formatted() -> String {
    FormatStyle().format(self)
  }

  @available(SwiftStdlib 5.7, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
