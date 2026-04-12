//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2023 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  import SwiftData
  import Testing

  @testable import NetbotLiteData

  @Suite struct V1Tests {

    @available(SwiftStdlib 5.9, *)
    @Test func models() async throws {
      let source = V1.models
      #expect(source.count == 10)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func versionIdentifier() async throws {
      #expect(V1.versionIdentifier == .init(1, 0, 0))
    }
  }
#endif
