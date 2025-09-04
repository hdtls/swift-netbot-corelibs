//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ProfileSupport

@available(SwiftStdlib 5.7, *)
extension AnyProxy {

  func buildAsRegex() -> some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      name
      /\ *= */
      kind.rawValue
      Optionally {
        ","
      }
      ZeroOrMore(.anyNonNewline)
    }
  }

  var ownedRulesRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      try! Regex<Substring>(
        AnyForwardingRule.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      // Expression of FINAL rule can be omitted
      /\, *(?:.+, *)?/
      name
      ZeroOrMore(.anyNonNewline)
    }
  }

  static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }
}
