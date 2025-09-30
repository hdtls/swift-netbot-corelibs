//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import Testing

@testable import AnlzrReports

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct ProcessReportTests {

  @available(SwiftStdlib 5.3, *)
  @Test func propertyInitialValues() async throws {
    let report = ProcessReport()
    #expect(report.processIdentifier == nil)
    #expect(report.program == nil)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func hashableConformance() async throws {
    let report = ProcessReport(
      processIdentifier: 52342
    )
    let expected = ProcessReport(
      processIdentifier: 52342
    )

    #expect(report == expected)

    let reports: Set<ProcessReport> = [report, expected]
    #expect(reports == [report])
  }

  @available(SwiftStdlib 5.3, *)
  @Test func codableConformance() async throws {
    let report = ProcessReport(
      processIdentifier: 52342
    )

    let data = try JSONEncoder().encode(report)
    let result = try JSONDecoder().decode(ProcessReport.self, from: data)
    #expect(result == report)
  }

  #if swift(>=6.3) || canImport(Darwin)
    @available(SwiftStdlib 5.9, *)
    @Test func initFromPersistentModel() throws {
      let model = V1._ProcessReport()
      model.processIdentifier = 12345
      let report = ProcessReport(persistentModel: model)
      #expect(report.processIdentifier == 12345)
    }
  #endif
}
