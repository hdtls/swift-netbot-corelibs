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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension AnyForwardingRule {

  static let delimiter = ","

  package static let sectionName = "[Rule]"

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.7, *)
  #endif
  package static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }

  /// Regular expression for match all forwarding rule with specified pattern.
  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.7, *)
  #endif
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.7, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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
