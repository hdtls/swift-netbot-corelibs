// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import RegexBuilder

@available(SwiftStdlib 5.3, *)
extension AnyForwardingRule {

  static let delimiter = ","

  package static let sectionName = "[Rule]"

  @available(SwiftStdlib 5.7, *)
  package static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }

  /// Regular expression for match all forwarding rule with specified pattern.
  @available(SwiftStdlib 5.7, *)
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

  @available(SwiftStdlib 5.7, *)
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
