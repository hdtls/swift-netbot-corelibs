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

import Testing

@testable import NetbotProfile

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.profileparser))
struct PropertiesParseStrategyTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  var parser: PropertiesParseStrategy { .init() }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: ["==", " = = ", "p1, p2 = 1", "p1"])
  func parsePropertiesFromInvalidInput(_ parseInput: String) async throws {
    let parseFunctions = [parser.parse, parser._parse, parser._parse0]

    for parse in parseFunctions {
      #expect(throws: CocoaError.self) {
        try parse(parseInput)
      }
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parse() async throws {
    let parseFunctions = [parser.parse, parser._parse, parser._parse0]

    for parse in parseFunctions {
      #expect(try parse("p1 = 1") == ["p1": ["1"]])
      #expect(try parse("p1 = 1, p2 = 2") == ["p1": ["1"], "p2": ["2"]])
      #expect(try parse("p1 = 1, p2 = 2, 3, 4") == ["p1": ["1"], "p2": ["2", "3", "4"]])
      #expect(try parse("p1 = 1, 2, 3, p2 = 2") == ["p1": ["1", "2", "3"], "p2": ["2"]])
      #expect(
        try parse("p1 = 1, 2, 3, p2 = 2, 3, 4, p3 = 3") == [
          "p1": ["1", "2", "3"], "p2": ["2", "3", "4"], "p3": ["3"],
        ])
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parsePropertiesFromInputContainingQuotationMarks() throws {

    let parseInput = "p1 = 1, \"p2 = 2\""

    let parseFunctions = [parser.parse, parser._parse, parser._parse0]

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput == ["p1": ["1", "p2 = 2"]])
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parsePropertiesFromInputContainingMultipleQuotationMarks() throws {
    let parseInput = "p1 = 1, \"p2 = 2\", p3 = \"a\""

    let parseFunctions = [parser.parse, parser._parse, parser._parse0]

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput == ["p1": ["1", "p2 = 2"], "p3": ["a"]])
    }
  }
}
