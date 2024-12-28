//
// See LICENSE.txt for license information
//

import Testing

@testable import _ResourceProcessing

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
