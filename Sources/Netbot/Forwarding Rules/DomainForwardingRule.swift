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

import CoWOptimization
import NetbotLite
import NetbotLiteData

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DomainForwardingRule._Storage: @unchecked Sendable {}
