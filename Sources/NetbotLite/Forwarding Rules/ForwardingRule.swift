// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2021 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NetbotLiteData

/// Types that conform to the `ForwardingRuleConvertible` protocol can provide
/// their own representation to be used when converting an instance to a `ForwardingRule`.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public protocol ForwardingRuleConvertible: Sendable {

  /// Converting an instance of conforming type to `ForwardingRule`.
  func asForwardingRule() -> any ForwardingRule
}

/// A `ForwardingRule` specifies how to route network traffic to the backend services.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public protocol ForwardingRule: Sendable {

  /// Forward protocol define how to forward connections using this rule.
  var forwardProtocol: any ForwardProtocolConvertible { get }

  /// A textual representation of this instance.
  var description: String { get }

  /// Predicate for test whether connection is satisfied with the rule.
  ///
  /// - Parameter connection: The test `Connection`.
  /// - Returns: True if connection is satisfied with the rule.
  func predicate(_ connection: Connection) throws -> Bool
}

/// A `FinalForwardingRule` specifies the final replacement of rule matching if no other rule matched.
///
/// There always contains one `FinalForwardingRule`, if user provide FinalForwardingRule implementation, it will be used as
/// final result, otherwise a builtin FinalForwardingRule will be used.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public protocol FinalForwardingRule: ForwardingRule {

}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension FinalForwardingRule {

  public var forwardProtocol: any ForwardProtocolConvertible { .direct }

  public var description: String { "FINAL" }

  public func predicate(_ connection: Connection) throws -> Bool {
    true
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
struct _FinalForwardingRule: FinalForwardingRule, ForwardingRuleConvertible {}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardingRuleConvertible where Self: ForwardingRule {

  public func asForwardingRule() -> any ForwardingRule {
    self
  }
}
