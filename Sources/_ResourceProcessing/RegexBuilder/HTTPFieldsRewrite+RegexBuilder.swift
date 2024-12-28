//
// See LICENSE.txt for license information
//

import RegexBuilder

extension HTTPFieldsRewrite {

  static let delimiter: Character = " "

  public static let sectionName = "[HTTP Fields Rewrite]"

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public static var regex:
    Regex<(Substring, Bool, Direction, Substring, Action, Substring, Substring?, Substring?)>
  {
    Regex {
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      TryCapture {
        try! Regex<Substring>(Direction.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        Direction(rawValue: String($0))
      }
      OneOrMore(.whitespace)
      Capture(OneOrMore(/[^ ]/))
      OneOrMore(.whitespace)
      TryCapture {
        try! Regex<Substring>(Action.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        Action(rawValue: String($0))
      }
      OneOrMore(.whitespace)
      Capture(OneOrMore(/[^ ]/))
      Optionally {
        OneOrMore(.whitespace)
        Capture(OneOrMore(/[^ ]/))
      }
      Optionally {
        OneOrMore(.whitespace)
        Capture(OneOrMore(/[^ ]/))
      }
      ZeroOrMore(.whitespace)
    }
  }
}
