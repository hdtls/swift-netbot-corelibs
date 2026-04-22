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
extension ProtocolDNS.Mapping {

  static let delimiter = "="

  package static let sectionName = "[DNS Mapping]"

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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.7, *)
  #endif
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
