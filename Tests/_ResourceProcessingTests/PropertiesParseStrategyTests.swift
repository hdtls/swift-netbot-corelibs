//
// See LICENSE.txt for license information
//

import Testing

@testable import _ResourceProcessing

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
    #expect(throws: CocoaError.self) {
      try parser.parse(parseInput)
    }
  }

  @Test func parse() async throws {
    #expect(try parser.parse("p1 = 1") == ["p1": ["1"]])
    #expect(try parser.parse("p1 = 1, p2 = 2") == ["p1": ["1"], "p2": ["2"]])
    #expect(try parser.parse("p1 = 1, p2 = 2, 3, 4") == ["p1": ["1"], "p2": ["2", "3", "4"]])
    #expect(try parser.parse("p1 = 1, 2, 3, p2 = 2") == ["p1": ["1", "2", "3"], "p2": ["2"]])
    #expect(
      try parser.parse("p1 = 1, 2, 3, p2 = 2, 3, 4, p3 = 3") == [
        "p1": ["1", "2", "3"], "p2": ["2", "3", "4"], "p3": ["3"],
      ])
  }

  @Test func parsePropertiesFromInputContainingQuotationMarks() throws {
    let parseInput = "p1 = 1, \"p2 = 2\""
    let parseOutput = try parser.parse(parseInput)
    #expect(parseOutput == ["p1": ["1", "p2 = 2"]])
  }

  @Test func parsePropertiesFromInputContainingMultipleQuotationMarks() throws {
    let parseInput = "p1 = 1, \"p2 = 2\", p3 = \"a\""
    let parseOutput = try parser.parse(parseInput)
    #expect(parseOutput == ["p1": ["1", "p2 = 2"], "p3": ["a"]])
  }
}
