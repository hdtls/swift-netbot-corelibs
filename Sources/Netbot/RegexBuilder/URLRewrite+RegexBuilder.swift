//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ProfileSupport

@available(SwiftStdlib 5.7, *)
extension URLRewrite {

  static let delimiter = ","

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

  static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }
}
