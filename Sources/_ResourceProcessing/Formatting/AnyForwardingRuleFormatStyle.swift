//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  public import FoundationEssentials
#else
  public import Foundation
#endif

extension AnyForwardingRule {
  /// Strategies for formatting a `AnyForwardingRule`.
  public struct FormatStyle: Sendable {
    /// Creates RuleFormatStyle with specified forwardingRule style.
    public init() {}
  }
}

extension AnyForwardingRule.FormatStyle {
  public func format(_ value: AnyForwardingRule) -> String {
    var formatOutput = ""
    if !value.isEnabled {
      formatOutput += "# "
    }
    formatOutput += value.kind.rawValue
    if value.kind == .final {
      if !value.value.isEmpty {
        formatOutput += "\(AnyForwardingRule.delimiter) \(value.value)"
      }
    } else {
      formatOutput += "\(AnyForwardingRule.delimiter) \(value.value)"
    }
    formatOutput += "\(AnyForwardingRule.delimiter) \(value.foreignKey)"
    if !value.comment.isEmpty {
      formatOutput += " // \(value.comment)"
    }
    return formatOutput
  }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AnyForwardingRule.FormatStyle: FormatStyle {
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension AnyForwardingRule.FormatStyle {
  public func parse(_ value: String) throws -> AnyForwardingRule {
    var parseOutput = ParseOutput()
    // Because the value of FINAL rules can be omitted,
    // so special treatment for FINAL rules is needed.
    let pattern =
      /\ *(?<flag># *)?(?<type>FINAL) *,(?: *(?<expression>[^,]+),)?(?: *(?<policy>[^\/]+))(?:\/\/ *(?<comment>.+))?/
    if let match = value.firstMatch(of: pattern) {
      parseOutput.isEnabled = match.flag?.isEmpty ?? true
      parseOutput.kind = .final
      parseOutput.value = String(match.expression ?? "")
      parseOutput.comment = String(match.comment ?? "")._trimmingWhitespaces()
      parseOutput.foreignKey = String(match.policy)._trimmingWhitespaces()
      return parseOutput
    } else {
      let pattern = AnyForwardingRule.regex
      guard let match = value.firstMatch(of: pattern) else {
        let example = AnyForwardingRule(kind: .geoip, value: "CN", comment: "")
        let exampleFormattedString = AnyForwardingRule.FormatStyle().format(example)
        let errorStr =
          "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
        throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
      }
      parseOutput.isEnabled = match.1
      parseOutput.kind = match.2
      parseOutput.value = match.3._trimmingWhitespaces()
      parseOutput.comment = match.5?._trimmingWhitespaces() ?? ""
      parseOutput.foreignKey = match.4._trimmingWhitespaces()
      return parseOutput
    }
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension AnyForwardingRule.FormatStyle: ParseStrategy {
}

extension AnyForwardingRule.FormatStyle {
  public var parseStrategy: AnyForwardingRule.FormatStyle {
    self
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension AnyForwardingRule.FormatStyle: ParseableFormatStyle {
}

extension AnyForwardingRule.FormatStyle: Codable, Hashable {}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension FormatStyle where Self == AnyForwardingRule.FormatStyle {
  public static var forwardingRule: Self { .init() }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ParseableFormatStyle where Self == AnyForwardingRule.FormatStyle {
  public static var forwardingRule: Self { .init() }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ParseStrategy where Self == AnyForwardingRule.FormatStyle {
  @_disfavoredOverload
  public static var forwardingRule: Self { .init() }
}

extension AnyForwardingRule {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == AnyForwardingRule {
      return v.format(self)
    }
  #else
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == AnyForwardingRule {
      v.format(self)
    }
  #endif

  /// Formats `self` using the complete pattern
  /// - Returns: A formatted string to describe the forwardingRule, such as "DOMAIN-SUFFIX,swift.org,DIRECT".
  public func formatted() -> String {
    FormatStyle().format(self)
  }

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
