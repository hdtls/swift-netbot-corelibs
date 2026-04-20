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

@Suite(.tags(.proxyGroup, .formatting))
struct AnyProxyGroupFormatStyleTests {

  @Test func formatGroupWithIntervalPolicies() {
    var formatInput = AnyProxyGroup(name: "example")
    var expected = "example = select, proxies = "
    #expect(formatInput.formatted() == expected)
    #expect(formatInput.formatted(AnyProxyGroup.FormatStyle()) == expected)
    #expect(AnyProxyGroup.FormatStyle().format(formatInput) == expected)
    #expect(AnyProxyGroup.FormatStyle.proxyGroup.format(formatInput) == expected)

    formatInput.lazyProxies.append("direct")
    formatInput.lazyProxies.append("reject")
    expected = "example = select, proxies = direct, reject"
    #expect(formatInput.formatted() == expected)
  }

  @Test func formatGroupWithExternalPolicies() {
    var formatInput = AnyProxyGroup(name: "example")
    formatInput.resource.source = .query
    var expected = "example = select, proxies-url = "
    #expect(formatInput.formatted() == expected)

    formatInput.resource.externalProxiesURL = .init(string: "https://example.com")
    expected = "example = select, proxies-url = https://example.com"
    #expect(formatInput.formatted() == expected)

    formatInput.resource.externalProxiesAutoUpdateTimeInterval = 86000
    expected =
      "example = select, proxies-url = https://example.com, proxies-auto-update-time-interval = 86000"
    #expect(formatInput.formatted() == expected)
  }

  @available(SwiftStdlib 5.7, *)
  @Test(arguments: [
    AnyProxyGroup.FormatStyle(),
    AnyProxyGroup.FormatStyle().parseStrategy,
    AnyProxyGroup.FormatStyle.proxyGroup,
  ])
  func parseGroupWithIntervalPolicies(_ parser: AnyProxyGroup.FormatStyle) throws {
    let parseInput = "example = select, proxies = direct"

    let parseOutput = try parser.parse(parseInput)
    #expect(parseOutput.name == "example")
    #expect(parseOutput.kind == .select)
    #expect(parseOutput.lazyProxies == ["direct"])
    #expect(parseOutput.resource.externalProxiesURL == nil)
    #expect(parseOutput.resource.source == .cache)
  }

  @available(SwiftStdlib 5.7, *)
  @Test func parseGroupWithExternalPolicies() throws {
    var parseInput = "example = select, proxies-url = https://example.com"
    var parseOutput = try AnyProxyGroup.FormatStyle().parse(parseInput)
    #expect(parseOutput.name == "example")
    #expect(parseOutput.kind == .select)
    #expect(parseOutput.lazyProxies == [])
    #expect(parseOutput.resource.externalProxiesURL == .init(string: "https://example.com"))
    #expect(parseOutput.resource.source == .query)

    parseInput =
      "example = select, proxies-url = https://example.com, proxies-auto-update-time-interval = 86000"
    parseOutput = try AnyProxyGroup.FormatStyle().parse(parseInput)
    #expect(parseOutput.name == "example")
    #expect(parseOutput.kind == .select)
    #expect(parseOutput.lazyProxies == [])
    #expect(parseOutput.resource.externalProxiesURL == .init(string: "https://example.com"))
    #expect(parseOutput.resource.externalProxiesAutoUpdateTimeInterval == 86000)
    #expect(parseOutput.resource.source == .query)
  }

  @available(SwiftStdlib 5.7, *)
  @Test(arguments: [
    "example = select",
    "example = select, proxies = ",
    "example = select, policiess = ",
    "example = select, proxies-url = -",
    "example = select, proxies-auto-update-time-interval = 86400",
    "example = select, proxies-url = https://example.com, proxies-auto-update-time-interval = abc",
  ])
  func parseGroupFromInvalidString(_ parseInput: String) {
    #expect(throws: CocoaError.self) {
      try AnyProxyGroup.FormatStyle().parse(parseInput)
    }
  }

  @Test func parseGroupContainsMultipleProxies() {
    let parseInput = "example = select, proxies = DIRECT, REJECT, REJECT-TINYGIF"
    #expect(throws: Never.self) {
      let parseOutput = try AnyProxyGroup.FormatStyle().parse(parseInput)
      #expect(parseOutput.name == "example")
      #expect(parseOutput.lazyProxies == ["DIRECT", "REJECT", "REJECT-TINYGIF"])
    }
  }

  @available(SwiftStdlib 5.5, *)
  @Test func formatStyleConformance() {
    var formatInput = AnyProxyGroup(name: "example")
    formatInput.lazyProxies.append("direct")
    #expect(formatInput.formatted(.proxyGroup) == "example = select, proxies = direct")
  }

  @available(SwiftStdlib 5.7, *)
  @Test func parseStrategyConformance() {
    #expect(throws: Never.self) {
      try AnyProxyGroup("example = select, proxies = direct", strategy: .proxyGroup)
    }
  }
}
