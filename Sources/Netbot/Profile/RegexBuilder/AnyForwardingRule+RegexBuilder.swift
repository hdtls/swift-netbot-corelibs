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
extension AnyForwardingRule {

  static let delimiter = ","

  package static let sectionName = "[Rule]"

  package static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }

  /// Regular expression for match all forwarding rule with specified pattern.
  package static var regex:
    Regex<(Substring, Bool, AnyForwardingRule.Kind, Substring, Substring, Substring?)>
  {
    Regex {
      /^/
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      ZeroOrMore(.whitespace)
      TryCapture {
        try! Regex<Substring>(
          AnyForwardingRule.Kind.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        AnyForwardingRule.Kind(rawValue: String($0))
      }
      ZeroOrMore(.whitespace)
      ","
      ZeroOrMore(.whitespace)
      Capture {
        OneOrMore(CharacterClass.anyOf(",").inverted)
      }
      ","
      ZeroOrMore(.whitespace)
      Capture {
        OneOrMore(CharacterClass.anyOf("/").inverted)
      }
      Optionally {
        "//"
        ZeroOrMore(.whitespace)
        Capture(ZeroOrMore(.anyNonNewline))
      }
      /$/
    }
  }

  package var regex: some RegexComponent {
    Regex {
      /^/
      ZeroOrMore(.whitespace)
      isEnabled ? "" : "#"
      ZeroOrMore(.whitespace)
      kind.rawValue
      AnyForwardingRule.delimiter
      ZeroOrMore(.whitespace)
      value
      AnyForwardingRule.delimiter
      ZeroOrMore(.whitespace)
      foreignKey
      ZeroOrMore(.whitespace)
      comment.isEmpty
        ? Regex {}
        : Regex {
          "//"
          ZeroOrMore(.whitespace)
          comment
          ZeroOrMore(.whitespace)
        }
      /$/
    }
  }
}
