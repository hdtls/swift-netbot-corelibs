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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension AnyForwardingRule {
  /// Strategies for formatting a `AnyForwardingRule`.
  public struct FormatStyle: Sendable {
    /// Creates RuleFormatStyle with specified forwardingRule style.
    public init() {}
  }
}

@available(SwiftStdlib 5.3, *)
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

@available(SwiftStdlib 5.5, *)
extension AnyForwardingRule.FormatStyle: FormatStyle {
}

@available(SwiftStdlib 5.3, *)
extension AnyForwardingRule.FormatStyle {

  public func parse(_ value: String) throws -> AnyForwardingRule {
    if #available(SwiftStdlib 5.7, *) {
      try _parse(value)
    } else {
      try _parse0(value)
    }
  }

  @available(SwiftStdlib 5.7, *)
  func _parse(_ value: String) throws -> AnyForwardingRule {
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

  func _parse0(_ value: String) throws -> AnyForwardingRule {
    var parseOutput = AnyForwardingRule()
    var parseInput = value
    // Check for disabled flag
    let isDisabled = parseInput.hasPrefix("#")
    if isDisabled {
      parseOutput.isEnabled = false
      parseInput.removeFirst()
    } else {
      parseOutput.isEnabled = true
    }

    // Remove extra spaces
    parseInput = parseInput._trimmingWhitespaces()

    // Find the last occurrence of // for comment
    var rulePart = parseInput
    if let commentRange = rulePart.range(of: "//", options: .backwards) {
      parseOutput.comment = rulePart[commentRange.upperBound...]._trimmingWhitespaces()
      rulePart = String(rulePart[..<commentRange.lowerBound])._trimmingWhitespaces()
    } else {
      parseOutput.comment = ""
    }

    // Now split by delimiter to get kind, value, foreignKey
    let delimiter = AnyForwardingRule.delimiter
    let pieces = rulePart.components(separatedBy: delimiter).map { $0._trimmingWhitespaces() }
    guard let kindStr = pieces.first, let kind = AnyForwardingRule.Kind(rawValue: kindStr) else {
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: "Unknown rule kind"])
    }
    parseOutput.kind = kind

    if kind == .final {
      guard pieces.count > 1 else {
        let example = AnyForwardingRule(kind: .geoip, value: "CN", comment: "")
        let exampleFormattedString = AnyForwardingRule.FormatStyle().format(example)
        let errorStr =
          "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
        throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
      }
      // For FINAL kind, value can be omitted
      parseOutput.value = pieces.count > 2 ? pieces[1] : ""
      parseOutput.foreignKey = pieces.count > 2 ? pieces[2] : pieces[1]
    } else {
      guard pieces.count > 2 else {
        let example = AnyForwardingRule(kind: .geoip, value: "CN", comment: "")
        let exampleFormattedString = AnyForwardingRule.FormatStyle().format(example)
        let errorStr =
          "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
        throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
      }
      parseOutput.value = pieces[1]
      parseOutput.foreignKey = pieces[2]
    }
    return parseOutput
  }
}

@available(SwiftStdlib 5.5, *)
extension AnyForwardingRule.FormatStyle: ParseStrategy {
}

@available(SwiftStdlib 5.3, *)
extension AnyForwardingRule.FormatStyle {
  public var parseStrategy: AnyForwardingRule.FormatStyle {
    self
  }
}

@available(SwiftStdlib 5.5, *)
extension AnyForwardingRule.FormatStyle: ParseableFormatStyle {
}

@available(SwiftStdlib 5.3, *)
extension AnyForwardingRule.FormatStyle: Codable, Hashable {}

@available(SwiftStdlib 5.5, *)
extension FormatStyle where Self == AnyForwardingRule.FormatStyle {
  public static var forwardingRule: Self { .init() }
}

@available(SwiftStdlib 5.5, *)
extension ParseableFormatStyle where Self == AnyForwardingRule.FormatStyle {
  public static var forwardingRule: Self { .init() }
}

@available(SwiftStdlib 5.5, *)
extension ParseStrategy where Self == AnyForwardingRule.FormatStyle {
  @_disfavoredOverload
  public static var forwardingRule: Self { .init() }
}

@available(SwiftStdlib 5.3, *)
extension AnyForwardingRule {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == AnyForwardingRule {
      return v.format(self)
    }
  #else
    @available(SwiftStdlib 5.5, *)
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

  @available(SwiftStdlib 5.5, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
