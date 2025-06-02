//
// See LICENSE.txt for license information
//

import RegexBuilder

extension DNSMapping {

  static let delimiter = "="

  public static let sectionName = "[DNS Mapping]"

  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  public static var regex: Regex<(Substring, Bool, Substring, (DNSMapping.Kind, Substring))> {
    Regex {
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      Capture {
        OneOrMore(.reluctant) {
          .anyNonNewline
        }
      }
      ZeroOrMore(.whitespace)
      delimiter
      ZeroOrMore(.whitespace)
      TryCapture {
        Regex {
          Optionally {
            "server:"
          }
          /.+/
        }
      } transform: { parseInput in
        let kind: DNSMapping.Kind
        let value: Substring
        if parseInput.hasPrefix("server:") {
          kind = .dns
          value = parseInput.replacing(/server: */, with: "")
        } else {
          kind = parseInput.isIPAddress() ? .mapping : .cname
          value = parseInput
        }
        return (kind, value)
      }
    }
  }
}
