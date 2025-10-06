//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

#if canImport(SwiftData)
  import Foundation
  import SwiftData
  import _ProfileSupport

  @available(SwiftStdlib 5.9, *)
  extension V1 {

    @Model public class _AnyProxyGroup {

      /// Name of the policy group.
      @Attribute(.unique)
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
      @Relationship(inverse: \_AnyForwardingRule.lazyProxyGroup)
      public var lazyForwardingRules: [_AnyForwardingRule] = []

      /// Relationship with `_Profile`..
      public var lazyProfile: _Profile?

      /// Create an instance of `AnyPolicy` with default values.
      public init() {
      }
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension AnyProxyGroup {

    public typealias PersistentModel = V1._AnyProxyGroup

    public init(persistentModel: PersistentModel) {
      self.init()
      name = persistentModel.name
      kind = persistentModel.kind
      resource = persistentModel.resource
      measurement = persistentModel.measurement
      creationDate = persistentModel.creationDate

      lazyProxies = persistentModel.lazyProxies.sorted(using: KeyPathComparator(\.creationDate))
        .map(\.name)
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
#endif
