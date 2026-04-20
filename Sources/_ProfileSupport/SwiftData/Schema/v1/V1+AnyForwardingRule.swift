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

#if canImport(SwiftData)
  import SwiftData
#endif

#if swift(>=6.3)
  import Observation
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1 {

  #if canImport(SwiftData)
    @Model
  #else
    #if swift(>=6.3)
      @Observable
    #endif
  #endif
  public class _AnyForwardingRule {

    /// A boolean value determinse whether the forwardingRule is enabled.
    public var isEnabled = true

    /// The kind of the available proxy rules.
    public typealias Kind = AnyForwardingRule.Kind

    /// Kind of the forwardingRule.
    public var kind = Kind.domain

    /// Match expressioin of the forwardingRule.
    public var value = ""

    /// Note of the the.
    public var comment = ""

    /// Sort priority of the forwardingRule.
    public var order = 0

    public typealias Notification = AnyForwardingRule.Notification

    /// forwardingRule matched notification.
    public var notification = Notification()

    /// Relationship with `_AnyProxyGroup`.
    public var lazyProxyGroup: _AnyProxyGroup?

    /// Relationship with `_AnyProxy`.
    public var lazyProxy: _AnyProxy?

    /// Relationship with `_Profile`.
    public var lazyProfile: _Profile?

    public init() {
    }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._AnyForwardingRule {

  public func mergeValues(_ data: AnyForwardingRule) {
    isEnabled = data.isEnabled
    kind = data.kind
    value = data.value
    comment = data.comment
    notification = data.notification
  }
}
