//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ProfileSupport

@available(SwiftStdlib 5.7, *)
extension AnyForwardingRule {

  static let delimiter = ","

  /// Regular expression for match current forwarding rule.
  func buildAsRegex() -> some RegexComponent {
    Regex {
      /^/
      ZeroOrMore(.whitespace)
      isEnabled ? "" : "#"
      ZeroOrMore(.whitespace)
      kind.rawValue
      AnyForwardingRule.delimiter
      ZeroOrMore(.whitespace)
      value
      AnyForwardingRule.delimiter
      ZeroOrMore(.whitespace)
      foreignKey
      ZeroOrMore(.whitespace)
      comment.isEmpty
        ? Regex {}
        : Regex {
          "//"
          ZeroOrMore(.whitespace)
          comment
          ZeroOrMore(.whitespace)
        }
      /$/
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
