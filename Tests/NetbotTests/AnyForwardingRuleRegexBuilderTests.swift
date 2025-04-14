//
// See LICENSE.txt for license information
//

import Testing
import _ResourceProcessing

@testable import Netbot

@Suite(.tags(.forwardingRule))
struct AnyForwardingRuleRegexBuilderTests {

  @Test(arguments: [
    "[Rule]", " [Rule]", "[Rule] ", " [Rule] ",
    "[Rule]   ",
  ])
  func ignoreWhitespacesWhileMatchingSection(_ parseInput: String) {
    let matches = parseInput.matches(of: AnyForwardingRule.sectionRegex)
    #expect(!matches.isEmpty)
  }

  @Test(arguments: [
    "[forwardingRule ]", "forwardingRule]", "[forwardingRule", " forwardingRule",
    "[ forwardingRule]",
  ])
  func matchInvalidSection(_ parseInput: String) {
    #expect(parseInput.matches(of: AnyForwardingRule.sectionRegex).isEmpty)
  }

  @Test func matchSpecifiedRule() {
    var forwardingRule = AnyForwardingRule()
    forwardingRule.kind = .domainSuffix
    forwardingRule.value = "swift.org"
    forwardingRule.foreignKey = "DIRECT"

    #expect(!"DOMAIN-SUFFIX, swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      !"DOMAIN-SUFFIX, swift.org, DIRECT\n".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      !"DOMAIN-SUFFIX, swift.org, DIRECT  ".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      !"DOMAIN-SUFFIX, swift.org, DIRECT  \n".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      "DOMAIN-SUFFIX, swift.org, DIRECT // COMMENT".matches(of: forwardingRule.buildAsRegex())
        .isEmpty)
    #expect("# DOMAIN-SUFFIX, swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("DOMAIN, http://swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      "DOMAIN-SET, http://domainset.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("GEOIP, CN, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("DOMAIN-KEYWORD, swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      "RULE-SET, http://ruleset.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("IP-CIDR, 103.22.200.0/22, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)

    forwardingRule.comment = "COMMENT"
    #expect(
      !"DOMAIN-SUFFIX, swift.org, DIRECT // COMMENT".matches(of: forwardingRule.buildAsRegex())
        .isEmpty)
    #expect("DOMAIN-SUFFIX, swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("DOMAIN, http://swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      "DOMAIN-SET, http://domainset.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("GEOIP, CN, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("DOMAIN-KEYWORD, swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      "RULE-SET, http://ruleset.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("IP-CIDR, 103.22.200.0/22, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)

    forwardingRule.isEnabled = false
    #expect(
      !"# DOMAIN-SUFFIX, swift.org, DIRECT // COMMENT".matches(of: forwardingRule.buildAsRegex())
        .isEmpty)
    #expect("DOMAIN-SUFFIX, swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("DOMAIN, http://swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      "DOMAIN-SET, http://domainset.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("GEOIP, CN, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("DOMAIN-KEYWORD, swift.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect(
      "RULE-SET, http://ruleset.org, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
    #expect("IP-CIDR, 103.22.200.0/22, DIRECT".matches(of: forwardingRule.buildAsRegex()).isEmpty)
  }
}
