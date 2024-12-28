//
// See LICENSE.txt for license information
//

import RegexBuilder

extension AnyProxyGroup {

  public static let sectionName = "[Proxy Group]"

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
