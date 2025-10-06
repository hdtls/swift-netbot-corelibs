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
extension StubbedHTTPResponse {
  public struct FormatStyle: Sendable {
    private var delimiter: Character { "," }

    public init() {}
  }
}

@available(SwiftStdlib 5.3, *)
extension StubbedHTTPResponse.FormatStyle {
  public func format(_ value: StubbedHTTPResponse) -> String {
    var formatOutput = value.isEnabled ? "" : "# "
    formatOutput += value.pattern
    if let bodyContentsURL = value.bodyContentsURL {
      formatOutput += "\(delimiter) "
      formatOutput += "data = \"\(bodyContentsURL.absoluteString)\""
    }
    formatOutput += "\(delimiter) "
    formatOutput += "status = \(value.status.code)"
    if !value.status.reasonPhrase.isEmpty {
      formatOutput += " \(value.status.reasonPhrase)"
    }
    if !value.additionalHTTPFields.isEmpty {
      formatOutput += "\(delimiter) "
      formatOutput += "additional-http-fields = \"\(value.additionalHTTPFields.formatted())\""
    }
    return formatOutput
  }
}

@available(SwiftStdlib 5.5, *)
extension StubbedHTTPResponse.FormatStyle: FormatStyle {
}

@available(SwiftStdlib 5.3, *)
extension StubbedHTTPResponse.FormatStyle {
  public func parse(_ value: String) throws -> StubbedHTTPResponse {
    func errorOut() -> CocoaError {
      var example = StubbedHTTPResponse()
      example.pattern = "(?:http://)swift.org"
      let exampleFormattedString = StubbedHTTPResponse.FormatStyle().format(StubbedHTTPResponse())
      let errorStr =
        "Cannot parse \(value). String should adhere to the preferred format, such as \(exampleFormattedString)."
      return CocoaError(.formatting, userInfo: [NSDebugDescriptionErrorKey: errorStr])
    }

    var parseInput = Substring(value._trimmingWhitespaces())

    var parseOutput = StubbedHTTPResponse()
    if let firstIndex = parseInput.firstIndex(of: "#") {
      parseInput = parseInput.suffix(from: firstIndex)
      parseOutput.isEnabled = false
    }

    if let end = parseInput.firstIndex(of: delimiter) {
      parseOutput.pattern = parseInput.prefix(upTo: end)._trimmingWhitespaces()
      let start = parseInput.index(after: end)
      guard start < parseInput.endIndex else {
        throw errorOut()
      }
      parseInput = parseInput.suffix(from: start)
    }

    let properties = try PropertiesParseStrategy().parse(String(parseInput))
    if let property = properties.first(where: { $0.key == "data" }) {
      guard let absoluteString = property.value.first else {
        throw errorOut()
      }
      parseOutput.bodyContentsURL = URL(string: absoluteString)
    }

    guard let property = properties.first(where: { $0.key == "status" }) else {
      throw errorOut()
    }
    guard let status = property.value.first else {
      throw errorOut()
    }
    let end = status.firstIndex(where: { !$0.isNumber })
    guard let end, let code = Int(status.prefix(upTo: end)._trimmingWhitespaces())
    else {
      throw errorOut()
    }
    let reasonPhrase = status.suffix(from: end)._trimmingWhitespaces()
    parseOutput.status = .init(code: code, reasonPhrase: String(reasonPhrase))

    if let property = properties.first(where: { $0.key == "additional-http-fields" }) {
      guard let httpFields = property.value.first else {
        throw errorOut()
      }
      do {
        parseOutput.additionalHTTPFields = try HTTPFields.FormatStyle().parse(httpFields)
      } catch {
        throw errorOut()
      }
    }
    return parseOutput
  }
}

@available(SwiftStdlib 5.5, *)
extension StubbedHTTPResponse.FormatStyle: ParseStrategy {
}

@available(SwiftStdlib 5.3, *)
extension StubbedHTTPResponse.FormatStyle {
  public var parseStrategy: StubbedHTTPResponse.FormatStyle {
    self
  }
}

@available(SwiftStdlib 5.5, *)
extension StubbedHTTPResponse.FormatStyle: ParseableFormatStyle {
}

@available(SwiftStdlib 5.3, *)
extension StubbedHTTPResponse.FormatStyle: Codable, Hashable {}

@available(SwiftStdlib 5.5, *)
extension FormatStyle where Self == StubbedHTTPResponse.FormatStyle {
  public static var stubbedHTTPResponse: Self { .init() }
}

@available(SwiftStdlib 5.5, *)
extension ParseStrategy where Self == StubbedHTTPResponse.FormatStyle {
  @_disfavoredOverload
  public static var stubbedHTTPResponse: Self { .init() }
}

@available(SwiftStdlib 5.3, *)
extension StubbedHTTPResponse {

  #if canImport(FoundationEssentials)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: FoundationEssentials.FormatStyle, S.FormatInput == StubbedHTTPResponse {
      return v.format(self)
    }
  #else
    @available(SwiftStdlib 5.5, *)
    public func formatted<S>(_ v: S) -> S.FormatOutput
    where S: Foundation.FormatStyle, S.FormatInput == StubbedHTTPResponse {
      return v.format(self)
    }
  #endif

  public func formatted() -> String {
    FormatStyle().format(self)
  }

  @available(SwiftStdlib 5.5, *)
  public init<T: ParseStrategy>(_ value: T.ParseInput, strategy: T) throws
  where T.ParseOutput == Self {
    self = try strategy.parse(value)
  }
}
