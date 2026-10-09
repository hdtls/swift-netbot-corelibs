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

import Logging
import NetbotLiteData
import NetbotNIO
import Testing

@testable import NetbotLite

@Suite struct ProcessResolverTests {

  @available(SwiftStdlib 6.0, *)
  @Test func processReportService() async throws {
    let application = AnalyzeBot(group: .default, logger: .init(label: ""))

    #expect(application.processResolver is DefaultProcessResolver)
    let p = try await application.processResolver.processInfo(connection: .init())
    #expect(p == .init())
  }
}
