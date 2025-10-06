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

import Testing

@testable import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.httpFieldsRewrite, .formatting))
struct HTTPFieldsRewriteFormatStyleTests {

  @Test(arguments: [
    HTTPFieldsRewrite.FormatStyle(),
    HTTPFieldsRewrite.FormatStyle.httpFieldsRewrite,
  ])
  func formatAddRewrite(_ formatter: HTTPFieldsRewrite.FormatStyle) throws {
    var httpFieldsRewrite = HTTPFieldsRewrite()
    httpFieldsRewrite.direction = .request
    httpFieldsRewrite.pattern = "(?:http://)?swift.org"
    httpFieldsRewrite.action = .add
    httpFieldsRewrite.name = "Proxy-Connection"
    httpFieldsRewrite.value = "keep-alive"
    httpFieldsRewrite.replacement = ""

    let expected = "request (?:http://)?swift.org add Proxy-Connection keep-alive"
    #expect(formatter.format(httpFieldsRewrite) == expected)
    #expect(httpFieldsRewrite.formatted() == expected)
    #expect(httpFieldsRewrite.formatted(formatter) == expected)
  }

  @Test(arguments: [
    HTTPFieldsRewrite.FormatStyle(),
    HTTPFieldsRewrite.FormatStyle.httpFieldsRewrite,
  ])
  func formatRemoveRewrite(_ formatter: HTTPFieldsRewrite.FormatStyle) throws {
    var httpFieldsRewrite = HTTPFieldsRewrite()
    httpFieldsRewrite.direction = .request
    httpFieldsRewrite.pattern = "(?:http://)?swift.org"
    httpFieldsRewrite.action = .remove
    httpFieldsRewrite.name = "Proxy-Connection"
    httpFieldsRewrite.value = "keep-alive"
    httpFieldsRewrite.replacement = ""

    let expected = "request (?:http://)?swift.org remove Proxy-Connection keep-alive"
    #expect(formatter.format(httpFieldsRewrite) == expected)
    #expect(httpFieldsRewrite.formatted() == expected)
    #expect(httpFieldsRewrite.formatted(formatter) == expected)
  }

  @Test(arguments: [
    HTTPFieldsRewrite.FormatStyle(),
    HTTPFieldsRewrite.FormatStyle.httpFieldsRewrite,
  ])
  func formatReplaceRewrwite(_ formatter: HTTPFieldsRewrite.FormatStyle) throws {
    var httpFieldsRewrite = HTTPFieldsRewrite()
    httpFieldsRewrite.direction = .request
    httpFieldsRewrite.pattern = "(?:http://)?swift.org"
    httpFieldsRewrite.action = .replace
    httpFieldsRewrite.name = "Proxy-Connection"
    httpFieldsRewrite.value = "keep-alive"
    httpFieldsRewrite.replacement = ""

    let expected = "request (?:http://)?swift.org replace Proxy-Connection keep-alive"
    #expect(formatter.format(httpFieldsRewrite) == expected)
    #expect(httpFieldsRewrite.formatted() == expected)
    #expect(httpFieldsRewrite.formatted(formatter) == expected)
  }

  @Test(arguments: [
    HTTPFieldsRewrite.FormatStyle(),
    HTTPFieldsRewrite.FormatStyle.httpFieldsRewrite,
  ])
  func formatReplaceWithRegexRewrite(_ formatter: HTTPFieldsRewrite.FormatStyle) throws {
    var httpFieldsRewrite = HTTPFieldsRewrite()
    httpFieldsRewrite.direction = .request
    httpFieldsRewrite.pattern = "(?:http://)?swift.org"
    httpFieldsRewrite.action = .replace
    httpFieldsRewrite.name = "Proxy-Connection"
    httpFieldsRewrite.value = "keep-alive"
    httpFieldsRewrite.replacement = "close"

    let expected = "request (?:http://)?swift.org replace Proxy-Connection keep-alive close"
    #expect(formatter.format(httpFieldsRewrite) == expected)
    #expect(httpFieldsRewrite.formatted() == expected)
    #expect(httpFieldsRewrite.formatted(formatter) == expected)
  }

  @Test(arguments: [
    HTTPFieldsRewrite.FormatStyle(),
    HTTPFieldsRewrite.FormatStyle().parseStrategy,
    HTTPFieldsRewrite.FormatStyle.httpFieldsRewrite,
  ])
  func parseAddRewrite(_ parser: HTTPFieldsRewrite.FormatStyle) throws {
    let parseInput = "request (?:http://)?swift.org add Proxy-Connection keep-alive"

    let parseFunctions: [(String) throws -> HTTPFieldsRewrite]
    if #available(SwiftStdlib 5.7, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)

      #expect(parseOutput.isEnabled)
      #expect(parseOutput.direction == .request)
      #expect(parseOutput.pattern == "(?:http://)?swift.org")
      #expect(parseOutput.action == .add)
      #expect(parseOutput.name == "Proxy-Connection")
      #expect(parseOutput.value == "keep-alive")
      #expect(parseOutput.replacement == "")
    }
  }

  @Test(arguments: [
    HTTPFieldsRewrite.FormatStyle(),
    HTTPFieldsRewrite.FormatStyle().parseStrategy,
    HTTPFieldsRewrite.FormatStyle.httpFieldsRewrite,
  ])
  func parseReplaceRewrite(_ parser: HTTPFieldsRewrite.FormatStyle) throws {
    let parseInput = "request (?:http://)?swift.org replace Proxy-Connection keep-alive"

    let parseFunctions: [(String) throws -> HTTPFieldsRewrite]
    if #available(SwiftStdlib 5.7, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)

      #expect(parseOutput.isEnabled)
      #expect(parseOutput.direction == .request)
      #expect(parseOutput.pattern == "(?:http://)?swift.org")
      #expect(parseOutput.action == .replace)
      #expect(parseOutput.name == "Proxy-Connection")
      #expect(parseOutput.value == "")
      #expect(parseOutput.replacement == "keep-alive")
    }
  }

  @Test(arguments: [
    HTTPFieldsRewrite.FormatStyle(),
    HTTPFieldsRewrite.FormatStyle().parseStrategy,
    HTTPFieldsRewrite.FormatStyle.httpFieldsRewrite,
  ])
  func parseReplaceWithRegexRewrite(_ parser: HTTPFieldsRewrite.FormatStyle) throws {
    let parseInput = "request (?:http://)?swift.org replace Set-Cookie 2592000 2590000"

    let parseFunctions: [(String) throws -> HTTPFieldsRewrite]
    if #available(SwiftStdlib 5.7, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)

      #expect(parseOutput.isEnabled)
      #expect(parseOutput.direction == .request)
      #expect(parseOutput.pattern == "(?:http://)?swift.org")
      #expect(parseOutput.action == .replace)
      #expect(parseOutput.name == "Set-Cookie")
      #expect(parseOutput.value == "2592000")
      #expect(parseOutput.replacement == "2590000")
    }
  }

  @Test(arguments: [
    "abc (?:http://)?example.com add Proxy-Connection keep-alive",
    "request (?:http://)?example.com plus Proxy-Connection keep-alive",
    "request (?:http://)?example.com remove",
  ])
  func parseFromInvalidString(_ parseInput: String) throws {
    let parser = HTTPFieldsRewrite.FormatStyle()

    let parseFunctions: [(String) throws -> HTTPFieldsRewrite]
    if #available(SwiftStdlib 5.7, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      #expect(throws: CocoaError.self) {
        try parse(parseInput)
      }
    }
  }

  @Test func formatStyleConformance() {
    var httpFieldsRewrite = HTTPFieldsRewrite()
    httpFieldsRewrite.direction = .request
    httpFieldsRewrite.pattern = "(?:http://)?swift.org"
    httpFieldsRewrite.action = .add
    httpFieldsRewrite.name = "Proxy-Connection"
    httpFieldsRewrite.value = "keep-alive"
    httpFieldsRewrite.replacement = ""

    let expected = "request (?:http://)?swift.org add Proxy-Connection keep-alive"
    #expect(httpFieldsRewrite.formatted(.httpFieldsRewrite) == expected)
  }

  @Test func parseStrategyConformance() {
    #expect(throws: Never.self) {
      try HTTPFieldsRewrite(
        "request (?:http://)?swift.org add Proxy-Connection keep-alive",
        strategy: .httpFieldsRewrite)
    }
  }
}
