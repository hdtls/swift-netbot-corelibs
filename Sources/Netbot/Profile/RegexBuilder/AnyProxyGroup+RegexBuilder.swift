// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import RegexBuilder

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension AnyProxyGroup {

  package static let sectionName = "[Proxy Group]"

  package static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }

  package static var regex: Regex<(Substring, Substring, AnyProxyGroup.Kind, Substring)> {
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

  package var regex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      name
      /\ *= */
      kind.rawValue
      ","
      ZeroOrMore(.whitespace)
      "proxies"
      /\ *= */
      OneOrMore {
        CharacterClass.anyNonNewline
        Optionally(",")
      }
    }
  }

  package var rulesRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      try! Regex<Substring>(
        AnyForwardingRule.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      /\, *(?:.+, *)?/
      name
      ZeroOrMore(.whitespace)
    }
  }
}
