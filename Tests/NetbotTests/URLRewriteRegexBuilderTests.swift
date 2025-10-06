//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import RegexBuilder
import Testing
import _ProfileSupport

@testable import Netbot

@Suite struct URLRewriteRegexBuilderTests {

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

  @Test(
    arguments: [
      "[URL  Rewrites]", "URL Rewrites]", "[URL Rewrites", " URL Rewrites", "[ URL Rewrites]",
    ]
  )
  func matchInvalidSection(_ testInput: String) {
    #expect(testInput.matches(of: URLRewrite.sectionRegex).isEmpty)
  }

  @Test(arguments: ["# http-fields, pattern, replacement", "found, pattern, replacement"])
  func matchAnyURLRewrite(_ testInput: String) {
    let matches = testInput.matches(of: URLRewrite.regex)
    #expect(!matches.isEmpty)
  }

  @Test func mtchSpecifiedURLRewrite() {
    var urlRewrite = URLRewrite()
    urlRewrite.type = .found
    urlRewrite.pattern = "http://swift.org"
    urlRewrite.destination = "https://swift.org"

    let regex = urlRewrite.buildAsRegex()
    #expect(!"found, http://swift.org, https://swift.org".matches(of: regex).isEmpty)
    #expect("reject, http://swift.org, https://swift.org".matches(of: regex).isEmpty)
    #expect("found, https://swift.org, https://swift.org".matches(of: regex).isEmpty)
  }
}
