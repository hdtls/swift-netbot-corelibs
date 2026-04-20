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

import Testing

@testable import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.formatting))
struct PropertiesParseStrategyTests {

  let parser = PropertiesParseStrategy()

  @Test(arguments: ["==", " = = ", "p1, p2 = 1", "p1"])
  func parsePropertiesFromInvalidInput(_ parseInput: String) async throws {
    let parseFunctions: [(String) throws -> [String: [String]]]
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

  @Test func parse() async throws {
    let parseFunctions: [(String) throws -> [String: [String]]]
    if #available(SwiftStdlib 5.7, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

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

  @Test func parsePropertiesFromInputContainingQuotationMarks() throws {

    let parseInput = "p1 = 1, \"p2 = 2\""

    let parseFunctions: [(String) throws -> [String: [String]]]
    if #available(SwiftStdlib 5.7, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput == ["p1": ["1", "p2 = 2"]])
    }
  }

  @Test func parsePropertiesFromInputContainingMultipleQuotationMarks() throws {
    let parseInput = "p1 = 1, \"p2 = 2\", p3 = \"a\""

    let parseFunctions: [(String) throws -> [String: [String]]]
    if #available(SwiftStdlib 5.7, *) {
      parseFunctions = [parser.parse, parser._parse, parser._parse0]
    } else {
      parseFunctions = [parser.parse, parser._parse0]
    }

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)
      #expect(parseOutput == ["p1": ["1", "p2 = 2"], "p3": ["a"]])
    }
  }
}
