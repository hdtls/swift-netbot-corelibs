//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import Foundation
  import SwiftData
  import _ProfileSupport

  @available(SwiftStdlib 5.9, *)
  extension V1 {

    @Model public class _HTTPFieldsRewrite {

      /// A boolean value determinse whether this rule is enabled or disabled.
      public var isEnabled = true

      /// An enum define HTTP directions.
      public typealias Direction = HTTPFieldsRewrite.Direction

      /// Direction of HTTP communication.
      public var direction = Direction.request

      /// Incoming request URL matching pattern.
      public var pattern = ""

      /// An enum define modification actions.
      public typealias Action = HTTPFieldsRewrite.Action

      /// Action for modification.
      public var action = Action.add

      /// HTTP header field name.
      public var name = ""

      /// A regex describing the field value to replace.
      public var replacement = ""

      /// HTTP header field value.
      public var value = ""

      /// The time the resource was created.
      public var creationDate = Date.now

      /// Relationship with `_Profile`.
      public var lazyProfile: _Profile?

      /// Create a `HTTPFieldsRewrite.PersistentModel` with default values.
      public init() {
      }
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension HTTPFieldsRewrite {

    public typealias PersistentModel = V1._HTTPFieldsRewrite

    public init(persistentModel: PersistentModel) {
      self.init()
      isEnabled = persistentModel.isEnabled
      direction = persistentModel.direction
      pattern = persistentModel.pattern
      action = persistentModel.action
      name = persistentModel.name
      replacement = persistentModel.replacement
      value = persistentModel.value
      creationDate = persistentModel.creationDate
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension V1._HTTPFieldsRewrite {
    public func mergeValues(_ data: HTTPFieldsRewrite) {
      isEnabled = data.isEnabled
      direction = data.direction
      pattern = data.pattern
      action = data.action
      name = data.name
      replacement = data.replacement
      value = data.value
      creationDate = data.creationDate
    }
  }
#endif
