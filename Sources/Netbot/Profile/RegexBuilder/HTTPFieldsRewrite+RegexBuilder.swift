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
extension HTTPFieldsRewrite {

  static let delimiter: Character = " "

  package static let sectionName = "[HTTP Fields Rewrite]"

  package static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }

  package static var regex:
    Regex<(Substring, Bool, Direction, Substring, Action, Substring, Substring?, Substring?)>
  {
    Regex {
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      TryCapture {
        try! Regex<Substring>(Direction.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        Direction(rawValue: String($0))
      }
      OneOrMore(.whitespace)
      Capture(OneOrMore(/[^ ]/))
      OneOrMore(.whitespace)
      TryCapture {
        try! Regex<Substring>(Action.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        Action(rawValue: String($0))
      }
      OneOrMore(.whitespace)
      Capture(OneOrMore(/[^ ]/))
      Optionally {
        OneOrMore(.whitespace)
        Capture(OneOrMore(/[^ ]/))
      }
      Optionally {
        OneOrMore(.whitespace)
        Capture(OneOrMore(/[^ ]/))
      }
      ZeroOrMore(.whitespace)
    }
  }

  package var regex: some RegexComponent {
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
}
