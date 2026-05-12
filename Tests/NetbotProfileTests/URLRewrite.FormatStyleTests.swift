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

@testable import NetbotProfile

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.profile, .profileparser, .httprewrites))
struct URLRewrite_FormatStyleTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    URLRewrite.FormatStyle(),
    URLRewrite.FormatStyle.urlRewrite,
  ])
  func format(_ formatter: URLRewrite.FormatStyle) throws {
    var urlRewrite = URLRewrite()
    urlRewrite.type = .found
    urlRewrite.pattern = "(?:http://)?swift.org"
    urlRewrite.destination = "https://swift.org"

    let expected = "found, (?:http://)?swift.org, https://swift.org"
    #expect(formatter.format(urlRewrite) == expected)
    #expect(urlRewrite.formatted() == expected)
    #expect(urlRewrite.formatted(formatter) == expected)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    URLRewrite.FormatStyle(),
    URLRewrite.FormatStyle().parseStrategy,
    URLRewrite.FormatStyle.urlRewrite,
  ])
  func parse(_ parser: URLRewrite.FormatStyle) throws {
    let parseInput = "found, (?:http://)?swift.org, https://swift.org"

    let parseFunctions = [parser.parse, parser._parse, parser._parse0]

    for parse in parseFunctions {
      let parseOutput = try parse(parseInput)

      #expect(parseOutput.isEnabled)
      #expect(parseOutput.type == .found)
      #expect(parseOutput.pattern == "(?:http://)?swift.org")
      #expect(parseOutput.destination == "https://swift.org")
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    "abc, (?:http://)?swift.org, https://swift.org",
    "found, (?:http://)?swift.org",
  ])
  func parseFromInvalidString(_ parseInput: String) throws {
    let parser = URLRewrite.FormatStyle()

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
  @Test func formatStyleConformance() {
    var urlRewrite = URLRewrite()
    urlRewrite.type = .found
    urlRewrite.pattern = "(?:http://)?swift.org"
    urlRewrite.destination = "https://swift.org"

    #expect(urlRewrite.formatted(.urlRewrite) == "found, (?:http://)?swift.org, https://swift.org")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func parseStrategyConformance() {
    #expect(throws: Never.self) {
      try URLRewrite("found, (?:http://)?swift.org, https://swift.org", strategy: .urlRewrite)
    }
  }
}
