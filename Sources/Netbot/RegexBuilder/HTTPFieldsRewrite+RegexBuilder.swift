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
extension HTTPFieldsRewrite {

  static let delimiter: Character = " "

  func buildAsRegex() -> some RegexComponent {
    switch action {
    case .add:
      return Regex {
        isEnabled ? "" : "# "
        direction.rawValue
        OneOrMore(.whitespace)
        pattern
        OneOrMore(.whitespace)
        action.rawValue
        OneOrMore(.whitespace)
        name
        OneOrMore(.whitespace)
        value
        ZeroOrMore(.whitespace)
      }
    case .remove:
      return Regex {
        isEnabled ? "" : "# "
        direction.rawValue
        OneOrMore(.whitespace)
        pattern
        OneOrMore(.whitespace)
        action.rawValue
        OneOrMore(.whitespace)
        name
        ZeroOrMore(.whitespace)
      }
    case .replace:
      return Regex {
        isEnabled ? "" : "# "
        direction.rawValue
        OneOrMore(.whitespace)
        pattern
        OneOrMore(.whitespace)
        action.rawValue
        OneOrMore(.whitespace)
        name
        OneOrMore(.whitespace)
        value.isEmpty
          ? Regex {
            replacement
            OneOrMore(.whitespace)
          }
          : Regex {
            value
            OneOrMore(.whitespace)
            replacement
            ZeroOrMore(.whitespace)
          }
      }
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
