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

import AnlzrReports
import Atomics
import Logging
import NEAddressProcessing
import NIOCore
import Testing

@testable import Networking

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@Suite struct ProcessReportTests {

  private let application = Analyzer(
    group: MultiThreadedEventLoopGroup.singleton,
    logger: .init(label: "")
  )

  @Test func processReportService() async throws {
    let application = Analyzer(
      group: MultiThreadedEventLoopGroup.singleton,
      logger: .init(label: "")
    )

    #expect(application.services.processReport.service as? DefaultProcessReporting != nil)
    let p = try await application.services.processReport.service.processInfo(
      address: .unix(path: "/var/run/tmp.socks"))
    #expect(p == .init())
  }
}
