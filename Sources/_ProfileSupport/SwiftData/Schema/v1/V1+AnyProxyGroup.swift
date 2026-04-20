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

@available(SwiftStdlib 5.9, *)
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

    /// An object representing network measurements.
    public typealias Measurement = AnyProxyGroup.Measurement

    /// Network measurements.
    public var measurement = Measurement()

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

@available(SwiftStdlib 5.9, *)
extension V1._AnyProxyGroup {
  public func mergeValues(_ data: AnyProxyGroup) {
    self.name = data.name
    self.kind = data.kind
    self.resource = data.resource
    self.measurement = data.measurement
    self.creationDate = data.creationDate
  }
}
