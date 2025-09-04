//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import SwiftData

  @available(SwiftStdlib 5.9, *)
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
