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

struct V1_PathReportTests {

  @available(SwiftStdlib 6.0, *)
  @Test("V1._PathReport default initialization")
  func pathReportDefaultInit() {
    let report = V1._PathReport()
    #expect(report.receivedIPPacketCount == 0)
    #expect(report.sentIPPacketCount == 0)
    #expect(report.receivedTransportByteCount == 0)
    #expect(report.receivedTransportDuplicateByteCount == 0)
    #expect(report.receivedTransportOutOfOrderByteCount == 0)
    #expect(report.sentTransportByteCount == 0)
    #expect(report.retransmittedTransportByteCount == 0)
    #expect(report.transportSmoothedRTT == 0)
    #expect(report.transportMinimumRTT == 0)
    #expect(report.transportRTTVariance == 0)
    #expect(report.receivedApplicationByteCount == 0)
    #expect(report.sentApplicationByteCount == 0)
  }

  @available(SwiftStdlib 6.0, *)
  @Test("DataTransferReport.PathReport default initialization")
  func dataTransferPathReportDefaultInit() {
    let report = DataTransferReport.PathReport()
    #expect(report.receivedIPPacketCount == 0)
    #expect(report.sentIPPacketCount == 0)
    #expect(report.receivedTransportByteCount == 0)
    #expect(report.receivedTransportDuplicateByteCount == 0)
    #expect(report.receivedTransportOutOfOrderByteCount == 0)
    #expect(report.sentTransportByteCount == 0)
    #expect(report.retransmittedTransportByteCount == 0)
    #expect(report.transportSmoothedRTT == 0)
    #expect(report.transportMinimumRTT == 0)
    #expect(report.transportRTTVariance == 0)
    #expect(report.receivedApplicationByteCount == 0)
    #expect(report.sentApplicationByteCount == 0)
  }

  @available(SwiftStdlib 6.0, *)
  @Test("Init from persistent model copies all values")
  func dataTransferPathReportFromPersistentModel() {
    let persistent = V1._PathReport()
    persistent.receivedIPPacketCount = 10
    persistent.sentIPPacketCount = 20
    persistent.receivedTransportByteCount = 30
    persistent.receivedTransportDuplicateByteCount = 40
    persistent.receivedTransportOutOfOrderByteCount = 50
    persistent.sentTransportByteCount = 60
    persistent.retransmittedTransportByteCount = 70
    persistent.transportSmoothedRTT = 1.1
    persistent.transportMinimumRTT = 2.2
    persistent.transportRTTVariance = 3.3
    persistent.receivedApplicationByteCount = 100
    persistent.sentApplicationByteCount = 200

    let report = DataTransferReport.PathReport(persistentModel: persistent)
    #expect(report.receivedIPPacketCount == 10)
    #expect(report.sentIPPacketCount == 20)
    #expect(report.receivedTransportByteCount == 30)
    #expect(report.receivedTransportDuplicateByteCount == 40)
    #expect(report.receivedTransportOutOfOrderByteCount == 50)
    #expect(report.sentTransportByteCount == 60)
    #expect(report.retransmittedTransportByteCount == 70)
    #expect(report.transportSmoothedRTT == 1.1)
    #expect(report.transportMinimumRTT == 2.2)
    #expect(report.transportRTTVariance == 3.3)
    #expect(report.receivedApplicationByteCount == 100)
    #expect(report.sentApplicationByteCount == 200)
  }

  @available(SwiftStdlib 6.0, *)
  @Test("mergeValues overwrites all values")
  func mergeValues() {
    let persistent = V1._PathReport()
    persistent.receivedIPPacketCount = 1
    persistent.sentIPPacketCount = 2
    persistent.receivedTransportByteCount = 3
    persistent.receivedTransportDuplicateByteCount = 4
    persistent.receivedTransportOutOfOrderByteCount = 5
    persistent.sentTransportByteCount = 6
    persistent.retransmittedTransportByteCount = 7
    persistent.transportSmoothedRTT = 8.8
    persistent.transportMinimumRTT = 9.9
    persistent.transportRTTVariance = 10.1
    persistent.receivedApplicationByteCount = 11
    persistent.sentApplicationByteCount = 12

    let report = DataTransferReport.PathReport(
      receivedIPPacketCount: 100,
      sentIPPacketCount: 200,
      receivedTransportByteCount: 300,
      receivedTransportDuplicateByteCount: 400,
      receivedTransportOutOfOrderByteCount: 500,
      sentTransportByteCount: 600,
      retransmittedTransportByteCount: 700,
      transportSmoothedRTT: 88.8,
      transportMinimumRTT: 99.9,
      transportRTTVariance: 101.1,
      receivedApplicationByteCount: 1111,
      sentApplicationByteCount: 1212
    )
    persistent.mergeValues(report)
    #expect(persistent.receivedIPPacketCount == 100)
    #expect(persistent.sentIPPacketCount == 200)
    #expect(persistent.receivedTransportByteCount == 300)
    #expect(persistent.receivedTransportDuplicateByteCount == 400)
    #expect(persistent.receivedTransportOutOfOrderByteCount == 500)
    #expect(persistent.sentTransportByteCount == 600)
    #expect(persistent.retransmittedTransportByteCount == 700)
    #expect(persistent.transportSmoothedRTT == 88.8)
    #expect(persistent.transportMinimumRTT == 99.9)
    #expect(persistent.transportRTTVariance == 101.1)
    #expect(persistent.receivedApplicationByteCount == 1111)
    #expect(persistent.sentApplicationByteCount == 1212)
  }
}

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  extension V1_PathReportTests {

    @available(SwiftStdlib 6.0, *)
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1._PathReport.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      let data = DataTransferReport.PathReport(
        receivedIPPacketCount: 123,
        sentIPPacketCount: 21,
        receivedTransportByteCount: 123,
        receivedTransportDuplicateByteCount: 123,
        receivedTransportOutOfOrderByteCount: 12,
        sentTransportByteCount: 2,
        retransmittedTransportByteCount: 234,
        transportSmoothedRTT: 23,
        transportMinimumRTT: 123,
        transportRTTVariance: 12,
        receivedApplicationByteCount: 1,
        sentApplicationByteCount: 241
      )

      let model = V1._PathReport()
      model.mergeValues(data)
      modelContext.insert(model)

      let fetched = try modelContext.fetch(FetchDescriptor<V1._PathReport>()).first
      let persistentModel = try #require(fetched)
      let result = DataTransferReport.PathReport(persistentModel: persistentModel)
      #expect(result == data)
    }
  }
#endif
