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

  @Suite("V1._PathReport and DataTransferReport.PathReport")
  struct PathReportTests {

    @available(SwiftStdlib 5.9, *)
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

    @available(SwiftStdlib 5.9, *)
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

    @available(SwiftStdlib 5.9, *)
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

    @available(SwiftStdlib 5.9, *)
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
#endif
