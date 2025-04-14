//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ResourceProcessing

extension URLRewrite {

  static let delimiter = ","

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  func buildAsRegex() -> some RegexComponent {
    Regex {
      isEnabled ? "" : "# "
      type.rawValue
      URLRewrite.delimiter
      ZeroOrMore(.whitespace)
      pattern
      URLRewrite.delimiter
      ZeroOrMore(.whitespace)
      destination
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
