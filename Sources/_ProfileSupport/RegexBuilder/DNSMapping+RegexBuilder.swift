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
extension DNSMapping {

  static let delimiter = "="

  public static let sectionName = "[DNS Mapping]"

  @available(SwiftStdlib 5.7, *)
  public static var regex: Regex<(Substring, Bool, Substring, (DNSMapping.Kind, Substring))> {
    Regex {
      TryCapture(Optionally(/\ *# +/)) { $0.isEmpty }
      Capture {
        OneOrMore(.reluctant) {
          .anyNonNewline
        }
      }
      ZeroOrMore(.whitespace)
      delimiter
      ZeroOrMore(.whitespace)
      TryCapture {
        Regex {
          Optionally {
            "server:"
          }
          /.+/
        }
      } transform: { parseInput in
        let kind: DNSMapping.Kind
        let value: Substring
        if parseInput.hasPrefix("server:") {
          kind = .dns
          value = parseInput.replacing(/server: */, with: "")
        } else {
          kind = parseInput.isIPAddress() ? .mapping : .cname
          value = parseInput
        }
        return (kind, value)
      }
    }
  }
}
