//
// See LICENSE.txt for license information
//

import RegexBuilder

extension URLRewrite {

  static let delimiter = ","

  public static let sectionName = "[URL Rewrite]"

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public static var regex: Regex<(Substring, Bool, RewriteType, Substring, Substring)> {
    Regex {
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      TryCapture {
        // TODO: It is safety or not??
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
