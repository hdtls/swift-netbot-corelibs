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

import HTTPTypes
import Testing

@testable import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.httpFieldsRewrite, .formatting))
struct HTTPFieldsFormatStyleTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func format() {
    let httpFields: HTTPFields = [.connection: "keep-alive", .contentLength: "0"]
    let expected = "Connection:keep-alive|Content-Length:0"

    #expect(HTTPFields.FormatStyle().format(httpFields) == expected)
    #expect(HTTPFields.FormatStyle.httpFields.format(httpFields) == expected)
    #expect(httpFields.formatted(HTTPFields.FormatStyle()) == expected)
    #expect(httpFields.formatted() == expected)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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
