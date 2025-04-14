//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ResourceProcessing

extension HTTPFieldsRewrite {

  static let delimiter: Character = " "

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
