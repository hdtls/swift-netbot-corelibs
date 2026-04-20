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
extension HTTPFieldsRewrite {

  static let delimiter: Character = " "

  package static let sectionName = "[HTTP Fields Rewrite]"

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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.7, *)
  #endif
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.7, *)
  #endif
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
