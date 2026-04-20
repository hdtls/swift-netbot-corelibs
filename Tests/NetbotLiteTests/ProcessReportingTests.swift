// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

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

  private let application = AnalyzeBot(
    group: MultiThreadedEventLoopGroup.singleton,
    logger: .init(label: "")
  )

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
