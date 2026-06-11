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

@available(SwiftStdlib 6.0, *)
@_cowOptimization
struct DomainSuffixForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var domainSuffix: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "DOMAIN-SUFFIX \(domainSuffix)"
  }

  init(domainSuffix: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domainSuffix: domainSuffix, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    guard let host = connection.originalRequest?.host(percentEncoded: false) else {
      return false
    }
    return host.hasSuffix(domainSuffix)
  }
}

@available(SwiftStdlib 6.0, *)
extension DomainSuffixForwardingRule._Storage: Hashable {
  static func == (
    lhs: DomainSuffixForwardingRule._Storage, rhs: DomainSuffixForwardingRule._Storage
  ) -> Bool {
    lhs.domainSuffix == rhs.domainSuffix
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(domainSuffix)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

@available(SwiftStdlib 6.0, *)
extension DomainSuffixForwardingRule._Storage: @unchecked Sendable {}
