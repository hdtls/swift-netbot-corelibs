//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import RegexBuilder

@available(SwiftStdlib 5.3, *)
extension AnyProxy {

  package static let sectionName = "[Proxy]"

  @available(SwiftStdlib 5.7, *)
  package static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }

  @available(SwiftStdlib 5.7, *)
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

  @available(SwiftStdlib 5.7, *)
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

  @available(SwiftStdlib 5.7, *)
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
