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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DNSMapping {
  public struct FormatStyle: Sendable {
    public init() {}
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DNSMapping.FormatStyle: FormatStyle {
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DNSMapping.FormatStyle {

  public func parse(_ value: String) throws -> DNSMapping {
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      if #available(SwiftStdlib 5.7, *) {
        try _parse(value)
      } else {
        try _parse0(value)
      }
    #else
      try _parse(value)
    #endif
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.7, *)
  #endif
  func _parse(_ value: String) throws -> DNSMapping {
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

  func _parse0(_ value: String) throws -> DNSMapping {
    var parseInput = value._trimmingWhitespaces()
    let isDisabled = parseInput.hasPrefix("#")
    parseInput = isDisabled ? parseInput.dropFirst()._trimmingWhitespaces() : parseInput

    // Find the separator ' ='
    guard let sepRange = parseInput.range(of: " =") else {
      let example = DNSMapping(domainName: "*.taobao.com", value: "223.6.6.6")
      let exampleFormattedString = DNSMapping.FormatStyle().format(example)
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }

    let domainName = String(parseInput[..<sepRange.lowerBound])._trimmingWhitespaces()
    var valuePart = String(parseInput[sepRange.upperBound...])._trimmingWhitespaces()

    let kind: DNSMapping.Kind
    if valuePart.hasPrefix("server:") {
      kind = .dns
      valuePart = String(valuePart.dropFirst("server:".count))._trimmingWhitespaces()
    } else {
      // Not a dns/server mapping, treat as mapping/cname (same as above _parse logic)
      kind = valuePart.isIPAddress() ? .mapping : .cname
    }
    // Validate valuePart
    if valuePart.contains("?") || valuePart.contains("=") {
      let example = DNSMapping(domainName: "*.taobao.com", value: "223.6.6.6")
      let exampleFormattedString = DNSMapping.FormatStyle().format(example)
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      throw CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }
    var parseOutput = DNSMapping()
    parseOutput.isEnabled = !isDisabled
    parseOutput.kind = kind
    parseOutput.domainName = domainName
    parseOutput.value = valuePart
    return parseOutput
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DNSMapping.FormatStyle: ParseStrategy {
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DNSMapping.FormatStyle {
  public var parseStrategy: DNSMapping.FormatStyle {
    self
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DNSMapping.FormatStyle: ParseableFormatStyle {
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DNSMapping.FormatStyle: Codable, Hashable {}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension FormatStyle where Self == DNSMapping.FormatStyle {
  public static var dnsMapping: Self { .init() }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ParseStrategy where Self == DNSMapping.FormatStyle {
  @_disfavoredOverload
  public static var dnsMapping: Self { .init() }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DNSMapping {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == DNSMapping {
      return v.format(self)
    }
  #else
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      @available(SwiftStdlib 5.5, *)
    #endif
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == DNSMapping {
      return v.format(self)
    }
  #endif

  public func formatted() -> String {
    FormatStyle().format(self)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.5, *)
  #endif
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
