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

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData
  import Testing

  @testable import NetbotLiteData

  @Suite struct V1Tests {

    @available(SwiftStdlib 6.0, *)
    @Test func models() async throws {
      let source = V1.models
      #expect(source.count == 10)
    }

    @available(SwiftStdlib 6.0, *)
    @Test func versionIdentifier() async throws {
      #expect(V1.versionIdentifier == .init(1, 0, 0))
    }
  }
#endif
