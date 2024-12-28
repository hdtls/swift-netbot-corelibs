//
// See LICENSE.txt for license information
//

import RegexBuilder

extension AnyProxyGroup {

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }
}
