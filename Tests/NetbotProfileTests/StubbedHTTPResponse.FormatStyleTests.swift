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
struct StubbedHTTPResponse_FormatStyleTests {

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: [
    StubbedHTTPResponse.FormatStyle(),
    StubbedHTTPResponse.FormatStyle.stubbedHTTPResponse,
  ])
  func format(_ formatter: StubbedHTTPResponse.FormatStyle) {
    var response = StubbedHTTPResponse()
    response.pattern = "^https://example.com"
    response.bodyContentsURL = URL(fileURLWithPath: "/var/tmp/data.json")
    response.additionalHTTPFields = [.contentType: "application/json"]

    let expected =
      "^https://example.com, data = \"file:///var/tmp/data.json\", status = 200 OK, additional-http-fields = \"Content-Type:application/json\""
    #expect(formatter.format(response) == expected)
    #expect(response.formatted() == expected)
    #expect(response.formatted(formatter) == expected)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func formatDisabledMock() {
    var response = StubbedHTTPResponse()
    response.isEnabled = false
    response.pattern = "^https://example.com"
    response.bodyContentsURL = URL(fileURLWithPath: "/var/tmp/data.json")

    #expect(
      response.formatted()
        == "# ^https://example.com, data = \"file:///var/tmp/data.json\", status = 200 OK")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func ignoreEmptyBodyWhileFormatting() {
    var response = StubbedHTTPResponse()
    response.pattern = "^https://example.com"

    let expected = "^https://example.com, status = 200 OK"
    #expect(response.formatted() == expected)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func ignoreEmptyResponseStatusReasonPhraseWhileFormatting() {
    var response = StubbedHTTPResponse()
    response.pattern = "^https://example.com"
    response.status = .init(code: 200)

    let expected = "^https://example.com, status = 200"
    #expect(response.formatted() == expected)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func ignoreEmptyHTTPFieldsWhileFormatting() {
    var response = StubbedHTTPResponse()
    response.pattern = "^https://example.com"

    let expected = "^https://example.com, status = 200 OK"
    #expect(response.formatted() == expected)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: [
    StubbedHTTPResponse.FormatStyle(),
    StubbedHTTPResponse.FormatStyle().parseStrategy,
    StubbedHTTPResponse.FormatStyle.stubbedHTTPResponse,
  ])
  func parse(_ parser: StubbedHTTPResponse.FormatStyle) throws {
    let parseInput =
      "^https://example.com, data = \"file:///var/tmp/data.json\", status = 200 OK, additional-http-fields = \"Content-Type:application/json\""
    let parseOutput = try parser.parse(parseInput)

    #expect(parseOutput.isEnabled)
    #expect(parseOutput.pattern == "^https://example.com")
    #expect(parseOutput.bodyContentsURL == URL(fileURLWithPath: "/var/tmp/data.json"))
    #expect(parseOutput.status == .ok)
    #expect(parseOutput.additionalHTTPFields == [.contentType: "application/json"])
  }

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: [
    ""
  ])
  func parseFromInvalidString(_ parseInput: String) throws {
    #expect(throws: CocoaError.self) {
      try StubbedHTTPResponse.FormatStyle().parse(parseInput)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func formatStyleConformance() {
    var response = StubbedHTTPResponse()
    response.pattern = "^https://example.com"

    #expect(response.formatted(.stubbedHTTPResponse) == "^https://example.com, status = 200 OK")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func parseStrategyConformance() {
    #expect(throws: Never.self) {
      try StubbedHTTPResponse(
        "^https://example.com, status = 200 OK", strategy: .stubbedHTTPResponse)
    }
  }
}
