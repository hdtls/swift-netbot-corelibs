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

import Testing

@testable import _ProfileSupport

@Suite(.tags(.forwardingRule))
struct AnyForwardingRuleRegexBuilderTests {

  @Test(
    arguments: [
      "# DOMAIN-SUFFIX, swift.org, DIRECT", "DOMAIN, https://swift.org, DIRECT",
      "DOMAIN-KEYWORD, swift, DIRECT // Comment",
      "DOMAIN, www.example.com, Auto URL Test",
      "DOMAIN, www.example1.com, Auto URL Test // Comment",
    ]
  )
  func matchAnyValidRule(_ testInput: String) {
    let matches = testInput.matches(of: AnyForwardingRule.regex)
    #expect(!matches.isEmpty)
  }
}
