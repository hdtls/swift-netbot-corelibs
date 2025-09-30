//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if swift(>=6.3) || canImport(Darwin)
  import Testing

  @testable import AnlzrReports

  @Suite struct V1_DataTransferReportTests {

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValues() async throws {
      let source = V1._DataTransferReport()
      #expect(source._duration == 0)
      #expect(source.duration == .seconds(0))
      #expect(source.durationFormatted == "0ms")
      #expect(source.pathReport == nil)
      #expect(source.aggregatePathReport == nil)
      #expect(source.pathReportFormatted == .init())
      #expect(source.aggregatePathReportFormatted == .init())
    }

    @available(SwiftStdlib 5.9, *)
    @Test func mergeValues() throws {
      let model = V1._DataTransferReport()
      model._duration = 1
      model.aggregatePathReport = .init()
      model.pathReport = .init()

      let report = DataTransferReport(
        duration: 99,
        aggregatePathReport: .init(receivedApplicationByteCount: 101),
        pathReport: .init(sentApplicationByteCount: 202)
      )
      model.mergeValues(report)
      #expect(model._duration == 99)
      #expect(model.aggregatePathReport?.receivedApplicationByteCount == 0)
      #expect(model.pathReport?.sentApplicationByteCount == 0)
      #expect(model.aggregatePathReportFormatted.receivedApplicationByteCount == "101 bytes")
      #expect(model.pathReportFormatted.sentApplicationByteCount == "202 bytes")
    }
  }
#endif
