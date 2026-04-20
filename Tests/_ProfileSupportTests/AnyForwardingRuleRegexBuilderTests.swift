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

@Suite(.tags(.forwardingRule))
struct AnyForwardingRuleRegexBuilderTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    "[Rule]", " [Rule]", "[Rule] ", " [Rule] ",
    "[Rule]   ",
  ])
  func ignoreWhitespacesWhileMatchingSection(_ parseInput: String) {
    let matches = parseInput.matches(of: AnyForwardingRule.sectionRegex)
    #expect(!matches.isEmpty)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    "[forwardingRule ]", "forwardingRule]", "[forwardingRule", " forwardingRule",
    "[ forwardingRule]",
  ])
  func matchInvalidSection(_ parseInput: String) {
    #expect(parseInput.matches(of: AnyForwardingRule.sectionRegex).isEmpty)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func matchSpecifiedRule() {
    var forwardingRule = AnyForwardingRule()
    forwardingRule.kind = .domainSuffix
    forwardingRule.value = "swift.org"
    forwardingRule.foreignKey = "DIRECT"

    #expect(!"DOMAIN-SUFFIX, swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      !"DOMAIN-SUFFIX, swift.org, DIRECT\n".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      !"DOMAIN-SUFFIX, swift.org, DIRECT  ".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      !"DOMAIN-SUFFIX, swift.org, DIRECT  \n".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      "DOMAIN-SUFFIX, swift.org, DIRECT // COMMENT".matches(of: forwardingRule.regex)
        .isEmpty)
    #expect("# DOMAIN-SUFFIX, swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("DOMAIN, http://swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      "DOMAIN-SET, http://domainset.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("GEOIP, CN, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("DOMAIN-KEYWORD, swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      "RULE-SET, http://ruleset.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("IP-CIDR, 103.22.200.0/22, DIRECT".matches(of: forwardingRule.regex).isEmpty)

    forwardingRule.comment = "COMMENT"
    #expect(
      !"DOMAIN-SUFFIX, swift.org, DIRECT // COMMENT".matches(of: forwardingRule.regex)
        .isEmpty)
    #expect("DOMAIN-SUFFIX, swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("DOMAIN, http://swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      "DOMAIN-SET, http://domainset.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("GEOIP, CN, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("DOMAIN-KEYWORD, swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      "RULE-SET, http://ruleset.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("IP-CIDR, 103.22.200.0/22, DIRECT".matches(of: forwardingRule.regex).isEmpty)

    forwardingRule.isEnabled = false
    #expect(
      !"# DOMAIN-SUFFIX, swift.org, DIRECT // COMMENT".matches(of: forwardingRule.regex)
        .isEmpty)
    #expect("DOMAIN-SUFFIX, swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("DOMAIN, http://swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      "DOMAIN-SET, http://domainset.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("GEOIP, CN, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("DOMAIN-KEYWORD, swift.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect(
      "RULE-SET, http://ruleset.org, DIRECT".matches(of: forwardingRule.regex).isEmpty)
    #expect("IP-CIDR, 103.22.200.0/22, DIRECT".matches(of: forwardingRule.regex).isEmpty)
  }
}
