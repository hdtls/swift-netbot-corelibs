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

@available(SwiftStdlib 6.0, *)
extension ProtocolDNS.Mapping {

  static let delimiter = "="

  package static let sectionName = "[DNS Mapping]"

  package static var sectionRegex: some RegexComponent {
    Regex {
      ZeroOrMore(.whitespace)
      sectionName
      ZeroOrMore(.whitespace)
      ZeroOrMore(.newlineSequence)
    }
  }

  package static var regex:
    Regex<(Substring, Bool, Substring, (ProtocolDNS.MappingStrategy, Substring))>
  {
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
        let dnsMappingStrategy: ProtocolDNS.MappingStrategy
        let value: Substring
        if parseInput.hasPrefix("server:") {
          dnsMappingStrategy = .dns
          value = parseInput.replacing(/server: */, with: "")
        } else {
          dnsMappingStrategy = parseInput.isIPAddress() ? .mapping : .cname
          value = parseInput
        }
        return (dnsMappingStrategy, value)
      }
    }
  }

  package var regex: some RegexComponent {
    Regex {
      /^ */
      isEnabled ? /\ */ : /\ *# */
      domainName
      /\ *= */
      strategy == .dns ? "server:\(value)" : value
      /\ *$/
    }
  }
}
