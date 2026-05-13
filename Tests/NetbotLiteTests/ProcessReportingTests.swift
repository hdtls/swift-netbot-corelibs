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
import NIOCore
import NetbotLiteData
import Testing

@testable import NetbotLite

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@Suite struct ProcessReportingTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func processReportService() async throws {
    let application = AnalyzeBot(
      group: MultiThreadedEventLoopGroup.singleton,
      logger: .init(label: "")
    )

    #expect(application.processInfo is DefaultProcessReporting)
    let p = try await application.processInfo.processInfo(connection: .init())
    #expect(p == .init())
  }
}
