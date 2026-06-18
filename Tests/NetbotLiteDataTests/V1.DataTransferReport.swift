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

@Suite struct V1_DataTransferReportTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValues() async throws {
    let source = V1._DataTransferReport()
    #expect(source.duration == .zero)
    #expect(source.durationFormatted == "0ms")
    #expect(source.pathReport == nil)
    #expect(source.aggregatePathReport == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mergeValues() throws {
    let model = V1._DataTransferReport()
    model.duration = .seconds(1)
    model.aggregatePathReport = .init()
    model.pathReport = .init()

    let aggregatePathReport = DataTransferReport.PathReport(
      receivedIPPacketCount: 23_423_424,
      sentIPPacketCount: 234252,
      receivedTransportByteCount: 234234,
      receivedTransportDuplicateByteCount: 23424,
      receivedTransportOutOfOrderByteCount: 455,
      sentTransportByteCount: 23_423_411,
      retransmittedTransportByteCount: 234,
      transportSmoothedRTT: 23,
      transportMinimumRTT: 23,
      transportRTTVariance: 44,
      receivedApplicationByteCount: 123_412_424,
      sentApplicationByteCount: 234231
    )

    let pathReport = DataTransferReport.PathReport(
      receivedIPPacketCount: 2_342_529_234,
      sentIPPacketCount: 2_342_352,
      receivedTransportByteCount: 304,
      receivedTransportDuplicateByteCount: 3447,
      receivedTransportOutOfOrderByteCount: 5734,
      sentTransportByteCount: 342,
      retransmittedTransportByteCount: 342,
      transportSmoothedRTT: 34,
      transportMinimumRTT: 32,
      transportRTTVariance: 57,
      receivedApplicationByteCount: 42_234_234,
      sentApplicationByteCount: 23424
    )
    let report = DataTransferReport(
      duration: .seconds(99),
      aggregatePathReport: aggregatePathReport,
      pathReport: pathReport
    )
    model.mergeValues(report)
    #expect(model.duration == .seconds(99))
    #expect(model.aggregatePathReport?.sentApplicationByteCount == 0)
    #expect(model.aggregatePathReport?.receivedIPPacketCount == 0)
    #expect(model.aggregatePathReport?.sentIPPacketCount == 0)
    #expect(model.aggregatePathReport?.receivedTransportByteCount == 0)
    #expect(model.aggregatePathReport?.receivedTransportDuplicateByteCount == 0)
    #expect(model.aggregatePathReport?.receivedTransportOutOfOrderByteCount == 0)
    #expect(model.aggregatePathReport?.sentTransportByteCount == 0)
    #expect(model.aggregatePathReport?.retransmittedTransportByteCount == 0)
    #expect(model.aggregatePathReport?.transportSmoothedRTT == 0)
    #expect(model.aggregatePathReport?.transportMinimumRTT == 0)
    #expect(model.aggregatePathReport?.transportRTTVariance == 0)
    #expect(model.aggregatePathReport?.receivedApplicationByteCount == 0)
    #expect(model.aggregatePathReport?.sentApplicationByteCount == 0)
    #expect(model.pathReport?.sentApplicationByteCount == 0)
    #expect(model.pathReport?.receivedIPPacketCount == 0)
    #expect(model.pathReport?.sentIPPacketCount == 0)
    #expect(model.pathReport?.receivedTransportByteCount == 0)
    #expect(model.pathReport?.receivedTransportDuplicateByteCount == 0)
    #expect(model.pathReport?.receivedTransportOutOfOrderByteCount == 0)
    #expect(model.pathReport?.sentTransportByteCount == 0)
    #expect(model.pathReport?.retransmittedTransportByteCount == 0)
    #expect(model.pathReport?.transportSmoothedRTT == 0)
    #expect(model.pathReport?.transportMinimumRTT == 0)
    #expect(model.pathReport?.transportRTTVariance == 0)
    #expect(model.pathReport?.receivedApplicationByteCount == 0)
    #expect(model.pathReport?.sentApplicationByteCount == 0)
  }
}

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  extension V1_DataTransferReportTests {

    @available(SwiftStdlib 6.0, *)
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1._DataTransferReport.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      let data = DataTransferReport(
        duration: .seconds(1),
        aggregatePathReport: .init(),
        pathReport: .init()
      )

      let model = V1._DataTransferReport()
      model.mergeValues(data)
      modelContext.insert(model)

      let fetched = try modelContext.fetch(FetchDescriptor<V1._DataTransferReport>()).first
      let persistentModel = try #require(fetched)
      let result = DataTransferReport(persistentModel: persistentModel)
      #expect(result == data)
    }
  }
#endif
