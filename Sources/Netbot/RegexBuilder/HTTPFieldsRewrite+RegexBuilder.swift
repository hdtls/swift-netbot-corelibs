//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ProfileSupport

@available(SwiftStdlib 5.7, *)
extension HTTPFieldsRewrite {

  static let delimiter: Character = " "

  func buildAsRegex() -> some RegexComponent {
    switch action {
    case .add:
      return Regex {
        isEnabled ? "" : "# "
        direction.rawValue
        OneOrMore(.whitespace)
        pattern
        OneOrMore(.whitespace)
        action.rawValue
        OneOrMore(.whitespace)
        name
        OneOrMore(.whitespace)
        value
        ZeroOrMore(.whitespace)
      }
    case .remove:
      return Regex {
        isEnabled ? "" : "# "
        direction.rawValue
        OneOrMore(.whitespace)
        pattern
        OneOrMore(.whitespace)
        action.rawValue
        OneOrMore(.whitespace)
        name
        ZeroOrMore(.whitespace)
      }
    case .replace:
      return Regex {
        isEnabled ? "" : "# "
        direction.rawValue
        OneOrMore(.whitespace)
        pattern
        OneOrMore(.whitespace)
        action.rawValue
        OneOrMore(.whitespace)
        name
        OneOrMore(.whitespace)
        value.isEmpty
          ? Regex {
            replacement
            OneOrMore(.whitespace)
          }
          : Regex {
            value
            OneOrMore(.whitespace)
            replacement
            ZeroOrMore(.whitespace)
          }
      }
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
