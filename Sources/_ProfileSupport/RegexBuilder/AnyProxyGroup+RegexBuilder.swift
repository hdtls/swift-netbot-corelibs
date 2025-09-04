//
// See LICENSE.txt for license information
//

import RegexBuilder

@available(SwiftStdlib 5.3, *)
extension AnyProxyGroup {

  public static let sectionName = "[Proxy Group]"

  @available(SwiftStdlib 5.7, *)
  public static var regex: Regex<(Substring, Substring, AnyProxyGroup.Kind, Substring)> {
    Regex {
      /([^=\n]+) *= */
      TryCapture {
        try! Regex<Substring>(
          AnyProxyGroup.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        AnyProxyGroup.Kind(rawValue: String($0))
      }

      // Capture policy resource.
      /\, *(.+) */
    }
  }
}
