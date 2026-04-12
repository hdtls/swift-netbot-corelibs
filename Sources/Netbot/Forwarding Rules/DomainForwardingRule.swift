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

import CoWOptimization
import NetbotLite
import NetbotLiteData

@available(SwiftStdlib 5.3, *)
@_cowOptimization
struct DomainForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var domain: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "DOMAIN \(domain)"
  }

  init(domain: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(domain: domain, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    connection.originalRequest?.host(percentEncoded: false) == domain
  }
}

@available(SwiftStdlib 5.3, *)
extension DomainForwardingRule._Storage: Hashable {
  static func == (lhs: DomainForwardingRule._Storage, rhs: DomainForwardingRule._Storage) -> Bool {
    lhs.domain == rhs.domain
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(domain)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

@available(SwiftStdlib 5.3, *)
extension DomainForwardingRule._Storage: @unchecked Sendable {}
