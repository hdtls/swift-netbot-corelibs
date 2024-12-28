//
// See LICENSE.txt for license information
//

import RegexBuilder

extension DNSMapping {

  static let delimiter = "="

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
