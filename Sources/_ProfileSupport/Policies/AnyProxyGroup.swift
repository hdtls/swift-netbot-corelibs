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
@_cowOptimization public struct AnyProxyGroup: Hashable, Sendable {

  /// Name of the policy group.
  public var name: String

  /// Type of the policy group.
  public var kind: Kind

  /// Resource of policies.
  public var resource: Resource

  /// Network measurements.
  public var measurement: Measurement

  /// The group's creation date.
  public var creationDate: Date

  /// Policies included in the policy group.
  public var lazyProxies: [String]

  /// Create an instance of `AnyProxyGroup` with specified name.
  public init(name: String = UUID().uuidString) {
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      let creationDate: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
    #else
      let creationDate = Date.now
    #endif
    self._storage = _Storage(
      name: name,
      kind: .select,
      resource: .init(),
      measurement: .init(),
      creationDate: creationDate,
      lazyProxies: []
    )
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension AnyProxyGroup._Storage: Hashable {
  @inlinable static func == (lhs: AnyProxyGroup._Storage, rhs: AnyProxyGroup._Storage) -> Bool {
    return lhs.name == rhs.name
      && lhs.kind == rhs.kind
      && lhs.resource == rhs.resource
      && lhs.measurement == rhs.measurement
      && lhs.creationDate == rhs.creationDate
      && lhs.lazyProxies == rhs.lazyProxies
  }

  @inlinable func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(kind)
    hasher.combine(resource)
    hasher.combine(measurement)
    hasher.combine(creationDate)
    hasher.combine(lazyProxies)
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension AnyProxyGroup._Storage: @unchecked Sendable {}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension AnyProxyGroup {

  public typealias Model = V1._AnyProxyGroup

  public init(persistentModel: Model) {
    self.init()
    name = persistentModel.name
    kind = persistentModel.kind
    resource = persistentModel.resource
    measurement = persistentModel.measurement
    creationDate = persistentModel.creationDate

    lazyProxies = persistentModel.lazyProxies
      .sorted(by: { $0.creationDate < $1.creationDate })
      .map(\.name)
  }
}
