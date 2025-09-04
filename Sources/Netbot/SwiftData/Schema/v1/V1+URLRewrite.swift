//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import Foundation
  import SwiftData
  import _ProfileSupport

  @available(SwiftStdlib 5.9, *)
  extension V1 {
    @Model public class _URLRewrite {

      /// A boolean value determinse whether this rule is enabled or disabled.
      public var isEnabled = true

      /// A redirection type representation object, define type of URLRewrite.
      public typealias RewriteType = URLRewrite.RewriteType

      /// Response status for this redirection.
      public var type = RewriteType.found

      /// Incoming request URL matching pattern.
      public var pattern = ""

      /// URL redirect destination.
      public var destination = ""

      /// The time the resource was created.
      public var creationDate = Date.now

      /// Relationship with `_Profile`.
      public var lazyProfile: _Profile?

      public init() {
      }
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension URLRewrite {

    public typealias PersistentModel = V1._URLRewrite

    public init(persistentModel: PersistentModel) {
      self.init()
      isEnabled = persistentModel.isEnabled
      type = persistentModel.type
      pattern = persistentModel.pattern
      destination = persistentModel.destination
      creationDate = persistentModel.creationDate
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension V1._URLRewrite {

    public func mergeValues(_ data: URLRewrite) {
      isEnabled = data.isEnabled
      type = data.type
      pattern = data.pattern
      destination = data.destination
      creationDate = data.creationDate
    }
  }
#endif
