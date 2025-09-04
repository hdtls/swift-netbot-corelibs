//
// See LICENSE.txt for license information
//

import RegexBuilder

@available(SwiftStdlib 5.3, *)
extension AnyProxy {

  public static let sectionName = "[Proxy]"

  @available(SwiftStdlib 5.7, *)
  public static var regex: Regex<(Substring, Substring, AnyProxy.Kind, Substring?)> {
    Regex {
      /([^=\n]+) *= */
      TryCapture {
        try! Regex<Substring>(AnyProxy.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        AnyProxy.Kind(rawValue: String($0))
      }
      /(?:,? *([^\n]+))?/
    }
  }
}
