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

/// First version of schema used for data persistent.
@available(SwiftStdlib 6.0, *)
public enum V1 {}

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  @available(SwiftStdlib 6.0, *)
  extension V1: VersionedSchema {
    public static var models: [any PersistentModel.Type] {
      [
        V1.Connection.self,
        V1.DataTransferReport.self,
        V1.DNSResolutionReport.self,
        V1.EstablishmentReport.self,
        V1.ForwardingReport.self,
        V1.PathReport.self,
        V1.ProcessReport.self,
        V1.Program.self,
        V1.Request.self,
        V1.Response.self,
      ]
    }

    public static var versionIdentifier: Schema.Version {
      .init(1, 0, 0)
    }
  }
#endif
