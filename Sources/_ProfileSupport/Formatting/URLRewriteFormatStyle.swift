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
extension URLRewrite {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension URLRewrite.FormatStyle {
  public func format(_ value: URLRewrite) -> String {
    var formatOutput = value.isEnabled ? value.type.rawValue : "# \(value.type.rawValue)"
    formatOutput += "\(URLRewrite.delimiter) \(value.pattern)"
    formatOutput += "\(URLRewrite.delimiter) \(value.destination)"
    return formatOutput
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension URLRewrite.FormatStyle: FormatStyle {
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension URLRewrite.FormatStyle {

  public func parse(_ value: String) throws -> URLRewrite {
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
  func _parse(_ value: String) throws -> URLRewrite {
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

  func _parse0(_ value: String) throws -> URLRewrite {
    // Prepare example for error message
    var example = URLRewrite()
    example.type = .found
    example.pattern = "(?:http://)swift.org"
    example.destination = "https://swift.org"
    let exampleFormattedString = example.formatted()

    // Split on delimiter
    let delimiter = URLRewrite.delimiter
    let parts = value.components(separatedBy: delimiter)

    // There should be exactly 3 parts: type, pattern, destination
    guard parts.count == 3 else {
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }

    // Detect if disabled (starts with '# ')
    let typeStr = parts[0]._trimmingWhitespaces()
    let (isEnabled, rawTypeStr): (Bool, String) = {
      if typeStr.hasPrefix("# ") {
        return (false, String(typeStr.dropFirst(2))._trimmingWhitespaces())
      } else {
        return (true, typeStr)
      }
    }()

    // Try to decode the type
    guard let type = URLRewrite.RewriteType(rawValue: rawTypeStr) else {
      let errorStr = "Cannot parse \(value). Unknown rule type: \(rawTypeStr)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }

    let pattern = parts[1]._trimmingWhitespaces()
    let destination = parts[2]._trimmingWhitespaces()

    var output = URLRewrite()
    output.isEnabled = isEnabled
    output.type = type
    output.pattern = pattern
    output.destination = destination
    return output
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension URLRewrite.FormatStyle: ParseStrategy {
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension URLRewrite.FormatStyle {
  public var parseStrategy: URLRewrite.FormatStyle {
    self
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension URLRewrite.FormatStyle: ParseableFormatStyle {
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension URLRewrite.FormatStyle: Codable, Hashable {}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension FormatStyle where Self == URLRewrite.FormatStyle {
  public static var urlRewrite: Self { .init() }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ParseStrategy where Self == URLRewrite.FormatStyle {
  @_disfavoredOverload
  public static var urlRewrite: Self { .init() }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension URLRewrite {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == URLRewrite {
      return v.format(self)
    }
  #else
    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
    #endif
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == URLRewrite {
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
