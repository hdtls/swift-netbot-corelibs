//
// See LICENSE.txt for license information
//

import RegexBuilder

extension AnyProxy {

  public static let sectionName = "[Proxy]"

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
