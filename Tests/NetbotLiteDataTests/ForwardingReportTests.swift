// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct ForwardingReportTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValues() async throws {
    let report = ForwardingReport()
    #expect(report._duration == 0)
    #expect(report.duration == .seconds(0))
    #expect(report.forwardProtocol == "DIRECT")
    #expect(report.forwardingRule == nil)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hashableConformance() async throws {
    let report = ForwardingReport(forwardingRule: "FINAL")
    let expected = ForwardingReport(forwardingRule: "FINAL")

    #expect(report == expected)

    let reports: Set<ForwardingReport> = [report, expected]
    #expect(reports == [report])
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func codableConformance() async throws {
    let report = ForwardingReport(forwardingRule: "FINAL")

    let data = try JSONEncoder().encode(report)
    let result = try JSONDecoder().decode(ForwardingReport.self, from: data)
    #expect(result == report)
  }
}
