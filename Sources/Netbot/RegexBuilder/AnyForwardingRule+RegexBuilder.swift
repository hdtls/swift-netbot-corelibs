//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ProfileSupport

extension AnyForwardingRule {

  static let delimiter = ","

  /// Regular expression for match current forwarding rule.
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
