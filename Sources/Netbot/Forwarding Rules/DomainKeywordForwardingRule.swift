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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DomainKeywordForwardingRule._Storage: @unchecked Sendable {}
