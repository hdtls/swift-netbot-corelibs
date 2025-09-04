//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ProfileSupport

@available(SwiftStdlib 5.7, *)
extension AnyProxyGroup {

  func buildAsRegex() -> some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      name
      /\ *= */
      kind.rawValue
      ","
      ZeroOrMore(.whitespace)
      "proxies"
      /\ *= */
      OneOrMore {
        CharacterClass.anyNonNewline
        Optionally(",")
      }
    }
  }

  var ownedRulesRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      try! Regex<Substring>(
        AnyForwardingRule.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      /\, *(?:.+, *)?/
      name
      ZeroOrMore(.whitespace)
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
