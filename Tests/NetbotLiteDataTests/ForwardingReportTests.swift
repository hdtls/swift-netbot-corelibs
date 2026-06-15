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

import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct ForwardingReportTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValues() async throws {
    let earliestBeginDate = Date.now
    let report = ForwardingReport(
      earliestBeginDate: earliestBeginDate,
      duration: .zero,
      forwardProtocol: "FINAL",
      forwardingRule: "DOMAIN-SUFFIX, test.com"
    )
    #expect(report.earliestBeginDate == earliestBeginDate)
    #expect(report.duration == .zero)
    #expect(report.forwardProtocol == "FINAL")
    #expect(report.forwardingRule == "DOMAIN-SUFFIX, test.com")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func hashableConformance() async throws {
    let earliestBeginDate = Date.now
    let report1 = ForwardingReport(
      earliestBeginDate: earliestBeginDate,
      duration: .seconds(1),
      forwardProtocol: "FINAL",
      forwardingRule: nil
    )
    let report2 = ForwardingReport(
      earliestBeginDate: earliestBeginDate,
      duration: .seconds(1),
      forwardProtocol: "FINAL",
      forwardingRule: nil
    )
    let report3 = ForwardingReport(
      earliestBeginDate: .now,
      duration: .seconds(1),
      forwardProtocol: "FINAL",
      forwardingRule: nil
    )

    #expect(report1 == report2)
    #expect(report1 != report3)

    let reports: Set<ForwardingReport> = [report1, report2, report3]
    #expect(reports == [report1, report3])
  }

  @available(SwiftStdlib 6.0, *)
  @Test func codableConformance() async throws {
    let report = ForwardingReport(
      earliestBeginDate: .now,
      duration: .seconds(1),
      forwardProtocol: "FINAL",
      forwardingRule: "FINAL"
    )

    let data = try JSONEncoder().encode(report)
    let result = try JSONDecoder().decode(ForwardingReport.self, from: data)
    #expect(result == report)
  }
}
