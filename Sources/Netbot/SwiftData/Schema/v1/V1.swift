//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import SwiftData

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  public enum V1: VersionedSchema {
    public static var models: [any PersistentModel.Type] {
      [
        _Profile.self, _AnyProxy.self, _AnyProxyGroup.self, _AnyForwardingRule.self,
        _DNSMapping.self,
        _HTTPFieldsRewrite.self, _StubbedHTTPResponse.self, _URLRewrite.self,
      ]
    }

    public static var versionIdentifier: Schema.Version {
      .init(1, 0, 0)
    }
  }
#endif
