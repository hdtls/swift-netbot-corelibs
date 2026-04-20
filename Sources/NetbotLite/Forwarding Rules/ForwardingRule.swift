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
@available(SwiftStdlib 5.3, *)
public protocol ForwardingRuleConvertible: Sendable {

  /// Converting an instance of conforming type to `ForwardingRule`.
  func asForwardingRule() -> any ForwardingRule
}

/// A `ForwardingRule` specifies how to route network traffic to the backend services.
@available(SwiftStdlib 5.3, *)
public protocol ForwardingRule: Sendable {

  /// A bool flag to determine whether a dns query is required when start rule matching.
  var requireIPAddress: Bool { get }

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

@available(SwiftStdlib 5.3, *)
extension ForwardingRule {

  public var requireIPAddress: Bool {
    false
  }
}

/// A `FinalForwardingRule` specifies the final replacement of rule matching if no other rule matched.
///
/// There always contains one `FinalForwardingRule`, if user provide FinalForwardingRule implementation, it will be used as
/// final result, otherwise a builtin FinalForwardingRule will be used.
@available(SwiftStdlib 5.3, *)
public protocol FinalForwardingRule: ForwardingRule {

}

@available(SwiftStdlib 5.3, *)
extension FinalForwardingRule {

  public var requireIPAddress: Bool { false }

  public var forwardProtocol: any ForwardProtocolConvertible { .direct }

  public var description: String { "FINAL" }

  public func predicate(_ connection: Connection) throws -> Bool {
    true
  }
}

@available(SwiftStdlib 5.3, *)
struct _FinalForwardingRule: FinalForwardingRule, ForwardingRuleConvertible {}

@available(SwiftStdlib 5.3, *)
extension ForwardingRuleConvertible where Self: ForwardingRule {

  public func asForwardingRule() -> any ForwardingRule {
    self
  }
}
