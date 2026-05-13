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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData)
  import SwiftData
#endif

#if swift(>=6.3)
  import Observation
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
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
  public class _AnyProxyGroup {

    /// Name of the policy group.
    #if canImport(SwiftData)
      @Attribute(.unique)
    #endif
    public var name = UUID().uuidString

    public typealias Kind = AnyProxyGroup.Kind

    /// Type of the policy group.
    public var kind = Kind.select

    /// An object representing external proxies resource.
    public typealias Resource = AnyProxyGroup.Resource

    /// Resource of policies.
    public var resource = Resource()

    /// Policy for internet latency test..
    public var measurePolicy = MeasurePolicy()

    /// Metrics for latency tests.
    public var transactionMetrics = TransactionMetrics()

    /// The group's creation date.
    public var creationDate = Date.now

    /// Relationship with `_AnyProxy`.
    public var lazyProxies: [_AnyProxy] = []

    /// Relationship with `_AnyForwardingRule`.
    #if canImport(SwiftData)
      @Relationship(inverse: \_AnyForwardingRule.lazyProxyGroup)
    #endif
    public var lazyForwardingRules: [_AnyForwardingRule] = []

    /// Relationship with `_Profile`..
    public var lazyProfile: _Profile?

    /// Create an instance of `AnyPolicy` with default values.
    public init() {
    }
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._AnyProxyGroup {

  /// Merge new values from DTO.
  /// - Parameter data: New `AnyProxyGroup` to merge.
  public func mergeValues(_ data: AnyProxyGroup) {
    self.name = data.name
    self.kind = data.kind
    self.resource = data.resource
    self.measurePolicy = data.measurePolicy
    self.transactionMetrics = data.transactionMetrics
    self.creationDate = data.creationDate
  }
}
