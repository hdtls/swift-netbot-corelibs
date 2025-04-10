//
// See LICENSE.txt for license information
//

import _ResourceProcessing

#if canImport(SwiftData)
  import Foundation
  import SwiftData

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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
