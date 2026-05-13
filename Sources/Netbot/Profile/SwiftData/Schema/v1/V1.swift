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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public enum V1 {}

#if canImport(SwiftData)
  import SwiftData

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension V1: VersionedSchema {
    public static var models: [any PersistentModel.Type] {
      [
        _Profile.self,
        _AnyProxy.self,
        _AnyProxyGroup.self,
        _AnyForwardingRule.self,
        _ProtocolDNS._Mapping.self,
        _HTTPFieldsRewrite.self,
        _StubbedHTTPResponse.self,
        _URLRewrite.self,
      ]
    }

    public static var versionIdentifier: Schema.Version {
      .init(1, 0, 0)
    }
  }
#endif
