//
// See LICENSE.txt for license information
//

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

  @Test func format() {
    let httpFields: HTTPFields = [.connection: "keep-alive", .contentLength: "0"]
    let expected = "Connection:keep-alive|Content-Length:0"

    #expect(HTTPFields.FormatStyle().format(httpFields) == expected)
    #expect(HTTPFields.FormatStyle.httpFields.format(httpFields) == expected)
    #expect(httpFields.formatted(HTTPFields.FormatStyle()) == expected)
    #expect(httpFields.formatted() == expected)
  }

  @available(SwiftStdlib 5.7, *)
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

  @available(SwiftStdlib 5.7, *)
  @Test func parse() throws {
    let expected: HTTPFields = [.connection: "keep-alive", .contentLength: "0"]
    let parseInput = "Connection:keep-alive|Content-Length:0"

    #expect(throws: Never.self) {
      let httpFields = try HTTPFields(parseInput, strategy: .httpFields)
      #expect(httpFields == expected)
    }
  }
}
