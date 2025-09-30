//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 5.9, *)
public enum V1 {}

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  import SwiftData

  @available(SwiftStdlib 5.9, *)
  extension V1: VersionedSchema {
    public static var models: [any PersistentModel.Type] {
      [
        _Connection.self,
        _DataTransferReport.self,
        _DNSResolutionReport.self,
        _EstablishmentReport.self,
        _ForwardingReport.self,
        _PathReport.self,
        _ProcessReport.self,
        _Program.self,
        _Request.self,
        _Response.self,
      ]
    }

    public static var versionIdentifier: Schema.Version {
      .init(1, 0, 0)
    }
  }
#endif
