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

@Suite(.tags(.formatting, .stubbedHTTPResponse))
struct StubbedHTTPResponseFormatStyleTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func formatDisabledMock() {
    var response = StubbedHTTPResponse()
    response.isEnabled = false
    response.pattern = "^https://example.com"
    response.bodyContentsURL = URL(fileURLWithPath: "/var/tmp/data.json")

    #expect(
      response.formatted()
        == "# ^https://example.com, data = \"file:///var/tmp/data.json\", status = 200 OK")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func ignoreEmptyBodyWhileFormatting() {
    var response = StubbedHTTPResponse()
    response.pattern = "^https://example.com"

    let expected = "^https://example.com, status = 200 OK"
    #expect(response.formatted() == expected)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func ignoreEmptyResponseStatusReasonPhraseWhileFormatting() {
    var response = StubbedHTTPResponse()
    response.pattern = "^https://example.com"
    response.status = .init(code: 200)

    let expected = "^https://example.com, status = 200"
    #expect(response.formatted() == expected)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func ignoreEmptyHTTPFieldsWhileFormatting() {
    var response = StubbedHTTPResponse()
    response.pattern = "^https://example.com"

    let expected = "^https://example.com, status = 200 OK"
    #expect(response.formatted() == expected)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    ""
  ])
  func parseFromInvalidString(_ parseInput: String) throws {
    #expect(throws: CocoaError.self) {
      try StubbedHTTPResponse.FormatStyle().parse(parseInput)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func formatStyleConformance() {
    var response = StubbedHTTPResponse()
    response.pattern = "^https://example.com"

    #expect(response.formatted(.stubbedHTTPResponse) == "^https://example.com, status = 200 OK")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseStrategyConformance() {
    #expect(throws: Never.self) {
      try StubbedHTTPResponse(
        "^https://example.com, status = 200 OK", strategy: .stubbedHTTPResponse)
    }
  }
}
