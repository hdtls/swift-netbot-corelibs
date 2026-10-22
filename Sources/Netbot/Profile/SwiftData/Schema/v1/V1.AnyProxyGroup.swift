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

import Observation

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData)
  import SwiftData
#else
  import NetbotSQL
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  @Model public class AnyProxyGroup {

    #Unique<AnyProxyGroup>([\.name])

    /// Name of the policy group.
    @Attribute(.unique)
    public var name = UUID().uuidString

    public typealias Kind = NetbotProfile.AnyProxyGroup.Kind

    /// Type of the policy group.
    public var kind = Kind.select

    /// An object representing external proxies resource.
    public typealias Resource = NetbotProfile.AnyProxyGroup.Resource

    /// Resource of policies.
    public var resource = Resource()

    /// Policy for internet latency test..
    public var measurePolicy = MeasurePolicy()

    /// Metrics for latency tests.
    public var transactionMetrics = TransactionMetrics()

    /// The group's creation date.
    public var creationDate = Date.now

    /// Relationship with `AnyProxy`.
    public var lazyProxies: [AnyProxy] = []

    /// Relationship with `AnyForwardingRule`.
    @Relationship(inverse: \AnyForwardingRule.lazyProxyGroup)
    public var lazyForwardingRules: [AnyForwardingRule] = []

    /// Relationship with `Profile`..
    public var lazyProfile: Profile?

    /// Create an instance of `AnyPolicy` with default values.
    public init() {
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.AnyProxyGroup {

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
