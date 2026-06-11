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

@available(SwiftStdlib 6.0, *)
extension AnyProxy {

  package static let sectionName = "[Proxy]"

  package static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }

  package static var regex: Regex<(Substring, Substring, AnyProxy.Kind, Substring?)> {
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

  package var regex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      name
      /\ *= */
      kind.rawValue
      Optionally {
        ","
      }
      ZeroOrMore(.anyNonNewline)
    }
  }

  package var rulesRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      try! Regex<Substring>(
        AnyForwardingRule.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      // Expression of FINAL rule can be omitted
      /\, *(?:.+, *)?/
      name
      ZeroOrMore(.anyNonNewline)
    }
  }
}
