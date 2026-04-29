// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension HTTPFieldsRewrite {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension HTTPFieldsRewrite.FormatStyle: FormatStyle {
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension HTTPFieldsRewrite.FormatStyle {

  public func parse(_ value: String) throws -> HTTPFieldsRewrite {
    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      if #available(SwiftStdlib 5.7, *) {
        try _parse(value)
      } else {
        try _parse0(value)
      }
    #else
      try _parse(value)
    #endif
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.7, *)
  #endif
  func _parse(_ value: String) throws -> HTTPFieldsRewrite {
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

  func _parse0(_ value: String) throws -> HTTPFieldsRewrite {
    // Remove leading/trailing spaces and check for disabling via '#'
    let trimmed = value._trimmingWhitespaces()
    let isEnabled: Bool
    let raw = trimmed.hasPrefix("#") ? String(trimmed.dropFirst())._trimmingWhitespaces() : trimmed
    isEnabled = !trimmed.hasPrefix("#")

    // Use the delimiter to split fields
    let parts = raw.split(separator: " ")

    // There must be at least: direction, pattern, action, name
    guard parts.count >= 4 else {
      var example = HTTPFieldsRewrite()
      example.direction = .request
      example.pattern = "(?:https://)example.org"
      example.action = .add
      example.name = "Proxy-Connection"
      example.value = "keep-alive"
      let exampleFormattedString = HTTPFieldsRewrite.FormatStyle().format(example)
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }
    var parseOutput = HTTPFieldsRewrite()
    parseOutput.isEnabled = isEnabled

    // Direction
    guard let direction = HTTPFieldsRewrite.Direction(rawValue: parts[0]._trimmingWhitespaces())
    else {
      throw CocoaError(
        .formatting, userInfo: [NSDebugDescriptionErrorKey: "Invalid direction: \(parts[0])"])
    }
    parseOutput.direction = direction

    // Pattern
    parseOutput.pattern = parts[1]._trimmingWhitespaces()
    // Action
    guard let action = HTTPFieldsRewrite.Action(rawValue: parts[2]._trimmingWhitespaces()) else {
      throw CocoaError(
        .formatting, userInfo: [NSDebugDescriptionErrorKey: "Invalid action: \(parts[2])"])
    }
    parseOutput.action = action
    // Name
    parseOutput.name = parts[3]._trimmingWhitespaces()

    // Parse remaining fields based on action
    switch action {
    case .add:
      // [direction, pattern, action, name, value]
      if parts.count > 4 {
        parseOutput.value = parts[4]._trimmingWhitespaces()
      }
    case .remove:
      // [direction, pattern, action, name, value]
      if parts.count > 4 {
        parseOutput.value = parts[4]._trimmingWhitespaces()
      }
    case .replace:
      // [direction, pattern, action, name, value, replacement?]
      if parts.count > 5 {
        parseOutput.value = parts[4]._trimmingWhitespaces()
        parseOutput.replacement = parts[5]._trimmingWhitespaces()
      } else if parts.count > 4 {
        // If only value is present, treat as replacement (like original)
        parseOutput.value = ""
        parseOutput.replacement = parts[4]._trimmingWhitespaces()
      }
    }
    return parseOutput
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension HTTPFieldsRewrite.FormatStyle: ParseStrategy {
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension HTTPFieldsRewrite.FormatStyle {
  public var parseStrategy: HTTPFieldsRewrite.FormatStyle {
    self
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension HTTPFieldsRewrite.FormatStyle: ParseableFormatStyle {
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension HTTPFieldsRewrite.FormatStyle: Codable, Hashable {}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension FormatStyle where Self == HTTPFieldsRewrite.FormatStyle {
  public static var httpFieldsRewrite: Self { .init() }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ParseStrategy where Self == HTTPFieldsRewrite.FormatStyle {
  @_disfavoredOverload
  public static var httpFieldsRewrite: Self { .init() }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension HTTPFieldsRewrite {
  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == HTTPFieldsRewrite {
      return v.format(self)
    }
  #else
    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
    #endif
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == HTTPFieldsRewrite {
      return v.format(self)
    }
  #endif

  public func formatted() -> String {
    FormatStyle().format(self)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #endif
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
