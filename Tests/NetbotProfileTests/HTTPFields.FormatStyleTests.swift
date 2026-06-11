// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import HTTPTypes
import Testing

@testable import NetbotProfile

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.profile, .profileparser, .httprewrites))
struct HTTPFields_FormatStyleTests {

  @available(SwiftStdlib 6.0, *)
  @Test func format() {
    let httpFields: HTTPFields = [.connection: "keep-alive", .contentLength: "0"]
    let expected = "Connection:keep-alive|Content-Length:0"

    #expect(HTTPFields.FormatStyle().format(httpFields) == expected)
    #expect(HTTPFields.FormatStyle.httpFields.format(httpFields) == expected)
    #expect(httpFields.formatted(HTTPFields.FormatStyle()) == expected)
    #expect(httpFields.formatted() == expected)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: [
    "",
    "⚽️:football",
  ])
  func parseWithInvalidInputString(_ parseInput: String) {

    #expect(throws: CocoaError.self) {
      try HTTPFields.FormatStyle().parse(parseInput)
    }
    #expect(throws: CocoaError.self) {
      try HTTPFields.FormatStyle().parseStrategy.parse(parseInput)
    }
    #expect(throws: CocoaError.self) {
      try HTTPFields.FormatStyle.httpFields.parse(parseInput)
    }
    #expect(throws: CocoaError.self) {
      try HTTPFields(parseInput, strategy: .httpFields)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: [
    HTTPFields.FormatStyle(),
    HTTPFields.FormatStyle().parseStrategy,
    HTTPFields.FormatStyle.httpFields,
  ])
  func parse(parser: HTTPFields.FormatStyle) throws {
    let expected: HTTPFields = [.connection: "keep-alive", .contentLength: "0"]
    let parseInput = "Connection:keep-alive|Content-Length:0"

    let parseFunctions: [(String) throws -> HTTPFields]
    parseFunctions = [parser.parse, parser._parse, parser._parse0]

    for parse in parseFunctions {
      #expect(throws: Never.self) {
        let httpFields = try parse(parseInput)
        #expect(httpFields == expected)
      }
    }

    #expect(throws: Never.self) {
      let httpFields = try HTTPFields(parseInput, strategy: .httpFields)
      #expect(httpFields == expected)
    }
  }
}
