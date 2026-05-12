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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension StubbedHTTPResponse {

  static let delimiter: Character = ","

  package static let sectionName = "[HTTP API Mocking]"

  package static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }

  package static var regex: Regex<(Substring, Bool, Substring, Substring)> {
    Regex {
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      OneOrMore(.whitespace)
      Capture(OneOrMore(/[^ ]/))
      OneOrMore(.whitespace)
      Capture(OneOrMore(.anyNonNewline))
    }
  }

  package var regex: some RegexComponent {
    Regex {
      isEnabled ? "" : "# "
      OneOrMore(.whitespace)
      pattern
      OneOrMore(.whitespace)
      bodyContentsURL != nil
        ? "data = \(bodyContentsURL!)"
        : ""
      status.reasonPhrase.isEmpty
        ? "status = \(status.code)"
        : "status = \(status.code) \(status.reasonPhrase)"
      additionalHTTPFields.isEmpty
        ? ""
        : "additional-http-fields = \(additionalHTTPFields.formatted())"
    }
  }
}
