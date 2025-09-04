//
// See LICENSE.txt for license information
//

import RegexBuilder

@available(SwiftStdlib 5.3, *)
extension URLRewrite {

  static let delimiter = ","

  public static let sectionName = "[URL Rewrite]"

  @available(SwiftStdlib 5.7, *)
  public static var regex: Regex<(Substring, Bool, RewriteType, Substring, Substring)> {
    Regex {
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      TryCapture {
        try! Regex<Substring>(RewriteType.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        RewriteType(rawValue: String($0))
      }
      ZeroOrMore(.whitespace)
      delimiter
      ZeroOrMore(.whitespace)
      Capture(OneOrMore(.anyNonNewline))
      ZeroOrMore(.whitespace)
      delimiter
      ZeroOrMore(.whitespace)
      Capture(OneOrMore(.anyNonNewline))
    }
  }
}
