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
struct FINALForwardingRule: FinalForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var condition: String

  var forwardProtocol: any ForwardProtocolConvertible

  @inlinable var description: String {
    "FINAL"
  }

  init(_ condition: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(condition: condition, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    true
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension FINALForwardingRule._Storage: Hashable {
  static func == (lhs: FINALForwardingRule._Storage, rhs: FINALForwardingRule._Storage) -> Bool {
    lhs.condition == rhs.condition
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(condition)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension FINALForwardingRule._Storage: @unchecked Sendable {}
