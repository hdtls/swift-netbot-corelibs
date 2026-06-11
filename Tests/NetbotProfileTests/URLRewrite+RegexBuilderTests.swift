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

import RegexBuilder
import Testing

@testable import NetbotProfile

@Suite(.tags(.profile, .profileparser, .httprewrites))
struct URLRewrite__RegexBuilderTests {

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: [
      "[URL Rewrite]", " [URL Rewrite]", "[URL Rewrite] ", " [URL Rewrite] ",
      "[URL Rewrite]   ",
    ]
  )
  func matchURLRewriteSection(_ testInput: String) {
    let matches = testInput.matches(of: URLRewrite.sectionRegex)
    #expect(!matches.isEmpty)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: [
      "[URL  Rewrites]", "URL Rewrites]", "[URL Rewrites", " URL Rewrites", "[ URL Rewrites]",
    ]
  )
  func matchInvalidSection(_ testInput: String) {
    #expect(testInput.matches(of: URLRewrite.sectionRegex).isEmpty)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: ["# http-fields, pattern, replacement", "found, pattern, replacement"])
  func matchAnyURLRewrite(_ testInput: String) {
    let matches = testInput.matches(of: URLRewrite.regex)
    #expect(!matches.isEmpty)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mtchSpecifiedURLRewrite() {
    var urlRewrite = URLRewrite()
    urlRewrite.type = .found
    urlRewrite.pattern = "http://swift.org"
    urlRewrite.destination = "https://swift.org"

    let regex = urlRewrite.regex
    #expect(!"found, http://swift.org, https://swift.org".matches(of: regex).isEmpty)
    #expect("reject, http://swift.org, https://swift.org".matches(of: regex).isEmpty)
    #expect("found, https://swift.org, https://swift.org".matches(of: regex).isEmpty)
  }
}
