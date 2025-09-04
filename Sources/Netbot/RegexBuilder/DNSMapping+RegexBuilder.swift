//
// See LICENSE.txt for license information
//

import RegexBuilder
import _ProfileSupport

@available(SwiftStdlib 5.7, *)
extension DNSMapping {

  static let delimiter = "="

  func buildAsRegex() -> some RegexComponent {
    Regex {
      /^ */
      isEnabled ? /\ */ : /\ *# */
      domainName
      /\ *= */
      kind == .dns ? "server:\(value)" : value
      /\ *$/
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
