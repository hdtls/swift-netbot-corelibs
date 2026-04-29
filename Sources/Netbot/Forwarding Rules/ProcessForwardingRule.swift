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

/// Forwarding rule base on Process.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@_cowOptimization
struct ProcessForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  var processName: String

  var forwardProtocol: any ForwardProtocolConvertible

  var description: String {
    "PROCESS-NAME \(processName)"
  }

  init(processName: String, forwardProtocol: any ForwardProtocolConvertible) {
    self._storage = _Storage(processName: processName, forwardProtocol: forwardProtocol)
  }

  func predicate(_ connection: Connection) throws -> Bool {
    guard let process = connection.processReport?.program else { return false }
    return process.executableURL?.lastPathComponent == processName
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ProcessForwardingRule._Storage: Hashable {
  static func == (lhs: ProcessForwardingRule._Storage, rhs: ProcessForwardingRule._Storage) -> Bool
  {
    lhs.processName == rhs.processName
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(processName)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ProcessForwardingRule._Storage: @unchecked Sendable {}
