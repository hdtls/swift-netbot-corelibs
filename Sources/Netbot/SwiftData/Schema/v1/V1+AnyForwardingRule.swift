//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  public import SwiftData

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension V1 {

    @Model public class _AnyForwardingRule {

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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension AnyForwardingRule {

    public typealias PersistentModel = V1._AnyForwardingRule

    public init(persistentModel: PersistentModel) {
      self.init()
      isEnabled = persistentModel.isEnabled
      kind = persistentModel.kind
      value = persistentModel.value
      comment = persistentModel.comment
      let lazyProxy = persistentModel.lazyProxy?.name
      let lazyProxyGroup = persistentModel.lazyProxyGroup?.name
      foreignKey = lazyProxy ?? lazyProxyGroup ?? "DIRECT"
      notification = persistentModel.notification
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension V1._AnyForwardingRule {

    public func mergeValues(_ data: AnyForwardingRule) {
      isEnabled = data.isEnabled
      kind = data.kind
      value = data.value
      comment = data.comment
      notification = data.notification
    }
  }
#endif
