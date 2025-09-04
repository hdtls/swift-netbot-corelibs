//
// See LICENSE.txt for license information
//

import RegexBuilder

@available(SwiftStdlib 5.3, *)
extension AnyForwardingRule {

  static let delimiter = ","

  public static let sectionName = "[Rule]"

  /// Regular expression for match all forwarding rule with specified pattern.
  @available(SwiftStdlib 5.7, *)
  public static var regex:
    Regex<(Substring, Bool, AnyForwardingRule.Kind, Substring, Substring, Substring?)>
  {
    Regex {
      /^/
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      ZeroOrMore(.whitespace)
      TryCapture {
        try! Regex<Substring>(
          AnyForwardingRule.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        AnyForwardingRule.Kind(rawValue: String($0))
      }
      ZeroOrMore(.whitespace)
      ","
      ZeroOrMore(.whitespace)
      Capture {
        OneOrMore(CharacterClass.anyOf(",").inverted)
      }
      ","
      ZeroOrMore(.whitespace)
      Capture {
        OneOrMore(CharacterClass.anyOf("/").inverted)
      }
      Optionally {
        "//"
        ZeroOrMore(.whitespace)
        Capture(ZeroOrMore(.anyNonNewline))
      }
      /$/
    }
  }
}
