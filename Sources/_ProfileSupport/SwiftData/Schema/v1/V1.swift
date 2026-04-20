// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public enum V1 {}

#if canImport(SwiftData)
  import SwiftData

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
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
        _DNSMapping.self,
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
