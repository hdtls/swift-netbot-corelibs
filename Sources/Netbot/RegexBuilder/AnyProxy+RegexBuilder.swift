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
import _ProfileSupport

@available(SwiftStdlib 5.7, *)
extension AnyProxy {

  func buildAsRegex() -> some RegexComponent {
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

  var ownedRulesRegex: some RegexComponent {
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

  static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }
}
