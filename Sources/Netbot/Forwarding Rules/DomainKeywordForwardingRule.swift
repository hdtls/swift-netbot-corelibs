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

import CoWOptimization
import NetbotLite
import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@_cowOptimization
struct DomainKeywordForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var domainKeyword: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "DOMAIN-KEYWORD \(domainKeyword)"
  }

  init(domainKeyword: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domainKeyword: domainKeyword, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    connection.originalRequest?.host(percentEncoded: false)?.contains(domainKeyword) ?? false
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DomainKeywordForwardingRule._Storage: Hashable {
  static func == (
    lhs: DomainKeywordForwardingRule._Storage, rhs: DomainKeywordForwardingRule._Storage
  ) -> Bool {
    lhs.domainKeyword == rhs.domainKeyword
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(domainKeyword)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DomainKeywordForwardingRule._Storage: @unchecked Sendable {}
