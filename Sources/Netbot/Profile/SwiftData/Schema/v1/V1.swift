// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

#if canImport(SwiftData)
  import SwiftData
#else
  import NetbotSQL
#endif

@available(SwiftStdlib 6.0, *)
public enum V1 {}

@available(SwiftStdlib 6.0, *)
extension V1: VersionedSchema {
  public static var models: [any PersistentModel.Type] {
    [
      V1.Profile.self,
      V1.AnyProxy.self,
      V1.AnyProxyGroup.self,
      V1.AnyForwardingRule.self,
      V1.ProtocolDNS.Mapping.self,
      V1.HTTPFieldsRewrite.self,
      V1.StubbedHTTPResponse.self,
      V1.URLRewrite.self,
    ]
  }

  public static var versionIdentifier: Schema.Version {
    .init(1, 0, 0)
  }
}
