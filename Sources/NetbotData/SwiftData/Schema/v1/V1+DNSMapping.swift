//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  public import Foundation
  public import SwiftData

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension V1 {

    /// An Object declaring DNS mapping rules.
    @Model public class _DNSMapping {

      /// A boolean value determinse whether this mapping is enabled.
      public var isEnabled = true

      public typealias Kind = DNSMapping.Kind

      /// The kind of the mapping.
      public var kind = Kind.mapping

      /// The domain to perform local DNS mapping.
      public var domainName = ""

      /// The mapped value.
      ///
      /// When the `kind` value is `mapping`, the value represents the mapped IP address.
      /// When the `kind` value is `cname`, the value represents the mapped new domain name.
      /// When the `kind` value is `dns`, the value represents the new domain name resolution server.
      public var value = ""

      /// The note on this DNS mapping.
      public var note = ""

      /// The date when the mapping created.
      public var creationDate = Date.now

      /// Relationship with `_Profile`.
      public var lazyProfile: _Profile?

      public init() {
      }
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension DNSMapping {

    public typealias PersistentModel = V1._DNSMapping

    public init(persistentModel: PersistentModel) {
      self.init()
      isEnabled = persistentModel.isEnabled
      kind = persistentModel.kind
      domainName = persistentModel.domainName
      value = persistentModel.value
      note = persistentModel.note
      creationDate = persistentModel.creationDate
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  extension V1._DNSMapping {

    public func mergeValues(_ data: DNSMapping) {
      isEnabled = data.isEnabled
      kind = data.kind
      domainName = data.domainName
      value = data.value
      note = data.note
      creationDate = data.creationDate
    }
  }
#endif
