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

@available(SwiftStdlib 6.0, *)
public enum V1 {}

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  @available(SwiftStdlib 6.0, *)
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
