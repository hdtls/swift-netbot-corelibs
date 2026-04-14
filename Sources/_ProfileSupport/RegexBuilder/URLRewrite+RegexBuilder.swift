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
extension URLRewrite {

  static let delimiter = ","

  package static let sectionName = "[URL Rewrite]"

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
  package static var regex: Regex<(Substring, Bool, RewriteType, Substring, Substring)> {
    Regex {
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      TryCapture {
        try! Regex<Substring>(RewriteType.allCases.map({ $0.rawValue }).joined(separator: "|"))
      } transform: {
        RewriteType(rawValue: String($0))
      }
      ZeroOrMore(.whitespace)
      delimiter
      ZeroOrMore(.whitespace)
      Capture(OneOrMore(.anyNonNewline))
      ZeroOrMore(.whitespace)
      delimiter
      ZeroOrMore(.whitespace)
      Capture(OneOrMore(.anyNonNewline))
    }
  }

  @available(SwiftStdlib 5.7, *)
  package var regex: some RegexComponent {
    Regex {
      isEnabled ? "" : "# "
      type.rawValue
      URLRewrite.delimiter
      ZeroOrMore(.whitespace)
      pattern
      URLRewrite.delimiter
      ZeroOrMore(.whitespace)
      destination
    }
  }
}
