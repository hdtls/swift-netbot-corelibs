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
extension DNSMapping {

  static let delimiter = "="

  func buildAsRegex() -> some RegexComponent {
    Regex {
      /^ */
      isEnabled ? /\ */ : /\ *# */
      domainName
      /\ *= */
      kind == .dns ? "server:\(value)" : value
      /\ *$/
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
