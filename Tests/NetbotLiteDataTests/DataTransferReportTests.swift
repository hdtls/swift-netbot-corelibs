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

@Suite struct DataTransferReportTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func pathReportPropertyInitialValues() async throws {
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func pathReportHashableConformance() async throws {
    let report = DataTransferReport.PathReport()
    #expect(report == .init())

    let reports = Set<DataTransferReport.PathReport>([report, report])
    #expect(reports == [report])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func pathReportCodableConformance() async throws {
    // Test encoding of default values
    let defaultReport = DataTransferReport.PathReport()
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = .sortedKeys
    let encodedDefault = try jsonEncoder.encode(defaultReport)
    let encodedDefaultString = String(data: encodedDefault, encoding: .utf8)
    let expectedJSONString =
      "{\"receivedApplicationByteCount\":0,\"receivedIPPacketCount\":0,\"receivedTransportByteCount\":0,\"receivedTransportDuplicateByteCount\":0,\"receivedTransportOutOfOrderByteCount\":0,\"retransmittedTransportByteCount\":0,\"sentApplicationByteCount\":0,\"sentIPPacketCount\":0,\"sentTransportByteCount\":0,\"transportMinimumRTT\":0,\"transportRTTVariance\":0,\"transportSmoothedRTT\":0}"
    #expect(encodedDefaultString == expectedJSONString)

    // Test decoding from JSON string
    let jsonData = expectedJSONString.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(DataTransferReport.PathReport.self, from: jsonData)
    let expected = DataTransferReport.PathReport(
      receivedIPPacketCount: 0,
      sentIPPacketCount: 0,
      receivedTransportByteCount: 0,
      receivedTransportDuplicateByteCount: 0,
      receivedTransportOutOfOrderByteCount: 0,
      sentTransportByteCount: 0,
      retransmittedTransportByteCount: 0,
      transportSmoothedRTT: 0,
      transportMinimumRTT: 0,
      transportRTTVariance: 0,
      receivedApplicationByteCount: 0,
      sentApplicationByteCount: 0
    )
    #expect(decoded == expected)

    // Decoding from JSON dictionary with non-default values
    let json = Data(
      """
      {
        "receivedApplicationByteCount": 5,
        "receivedIPPacketCount": 6,
        "receivedTransportByteCount": 7,
        "receivedTransportDuplicateByteCount": 8,
        "receivedTransportOutOfOrderByteCount": 9,
        "retransmittedTransportByteCount": 10,
        "sentApplicationByteCount": 11,
        "sentIPPacketCount": 12,
        "sentTransportByteCount": 13,
        "transportMinimumRTT": 1,
        "transportRTTVariance": 2,
        "transportSmoothedRTT": 3
      }
      """.utf8
    )
    let decodedNonDefault = try JSONDecoder().decode(DataTransferReport.PathReport.self, from: json)
    let expectedNonDefault = DataTransferReport.PathReport(
      receivedIPPacketCount: 6,
      sentIPPacketCount: 12,
      receivedTransportByteCount: 7,
      receivedTransportDuplicateByteCount: 8,
      receivedTransportOutOfOrderByteCount: 9,
      sentTransportByteCount: 13,
      retransmittedTransportByteCount: 10,
      transportSmoothedRTT: 3,
      transportMinimumRTT: 1,
      transportRTTVariance: 2,
      receivedApplicationByteCount: 5,
      sentApplicationByteCount: 11
    )
    #expect(decodedNonDefault == expectedNonDefault)

    // Round-trip test: encode and decode with non-default values
    let roundTripOriginal = expectedNonDefault
    let roundTripData = try JSONEncoder().encode(roundTripOriginal)
    let roundTripDecoded = try JSONDecoder().decode(
      DataTransferReport.PathReport.self, from: roundTripData)
    #expect(roundTripDecoded == roundTripOriginal)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValues() async throws {
    let report = DataTransferReport()
    #expect(report._duration == 0)
    #expect(report.duration == .seconds(0))
    #expect(report.aggregatePathReport == .init())
    #expect(report.pathReport == .init())
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hashableConformance() async throws {
    let report = DataTransferReport()
    let expected = DataTransferReport()

    #expect(report == expected)

    let reports: Set<DataTransferReport> = [report, expected]
    #expect(reports == [report])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func codableConformance() async throws {
    let report = DataTransferReport()

    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = .sortedKeys
    let data = try jsonEncoder.encode(report)
    let encodedString = String(data: data, encoding: .utf8)
    let expectedJSONString =
      "{\"_duration\":0,\"aggregatePathReport\":{\"receivedApplicationByteCount\":0,\"receivedIPPacketCount\":0,\"receivedTransportByteCount\":0,\"receivedTransportDuplicateByteCount\":0,\"receivedTransportOutOfOrderByteCount\":0,\"retransmittedTransportByteCount\":0,\"sentApplicationByteCount\":0,\"sentIPPacketCount\":0,\"sentTransportByteCount\":0,\"transportMinimumRTT\":0,\"transportRTTVariance\":0,\"transportSmoothedRTT\":0},\"pathReport\":{\"receivedApplicationByteCount\":0,\"receivedIPPacketCount\":0,\"receivedTransportByteCount\":0,\"receivedTransportDuplicateByteCount\":0,\"receivedTransportOutOfOrderByteCount\":0,\"retransmittedTransportByteCount\":0,\"sentApplicationByteCount\":0,\"sentIPPacketCount\":0,\"sentTransportByteCount\":0,\"transportMinimumRTT\":0,\"transportRTTVariance\":0,\"transportSmoothedRTT\":0}}"
    #expect(encodedString == expectedJSONString)

    let result = try JSONDecoder().decode(DataTransferReport.self, from: data)
    #expect(result == report)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func pathReportOperatorTests() async throws {
    let lhs = DataTransferReport.PathReport(
      receivedIPPacketCount: 10,
      sentIPPacketCount: 20,
      receivedTransportByteCount: 30,
      receivedTransportDuplicateByteCount: 40,
      receivedTransportOutOfOrderByteCount: 50,
      sentTransportByteCount: 60,
      retransmittedTransportByteCount: 70,
      transportSmoothedRTT: 0.5,
      transportMinimumRTT: 0.1,
      transportRTTVariance: 0.2,
      receivedApplicationByteCount: 80,
      sentApplicationByteCount: 90
    )
    let rhs = DataTransferReport.PathReport(
      receivedIPPacketCount: 1,
      sentIPPacketCount: 2,
      receivedTransportByteCount: 3,
      receivedTransportDuplicateByteCount: 4,
      receivedTransportOutOfOrderByteCount: 5,
      sentTransportByteCount: 6,
      retransmittedTransportByteCount: 7,
      transportSmoothedRTT: 1.5,
      transportMinimumRTT: 1.1,
      transportRTTVariance: 1.2,
      receivedApplicationByteCount: 8,
      sentApplicationByteCount: 9
    )
    // &+ operator
    let plus = lhs &+ rhs
    #expect(plus.receivedIPPacketCount == 11)
    #expect(plus.sentIPPacketCount == 22)
    #expect(plus.receivedTransportByteCount == 33)
    #expect(plus.receivedTransportDuplicateByteCount == 44)
    #expect(plus.receivedTransportOutOfOrderByteCount == 55)
    #expect(plus.sentTransportByteCount == 66)
    #expect(plus.retransmittedTransportByteCount == 77)
    // RTT fields use rhs
    #expect(plus.transportSmoothedRTT == 1.5)
    #expect(plus.transportMinimumRTT == 1.1)
    #expect(plus.transportRTTVariance == 1.2)
    #expect(plus.receivedApplicationByteCount == 88)
    #expect(plus.sentApplicationByteCount == 99)

    // &- operator
    let minus = lhs &- rhs
    #expect(minus.receivedIPPacketCount == 9)
    #expect(minus.sentIPPacketCount == 18)
    #expect(minus.receivedTransportByteCount == 27)
    #expect(minus.receivedTransportDuplicateByteCount == 36)
    #expect(minus.receivedTransportOutOfOrderByteCount == 45)
    #expect(minus.sentTransportByteCount == 54)
    #expect(minus.retransmittedTransportByteCount == 63)
    // RTT fields use rhs
    #expect(minus.transportSmoothedRTT == 1.5)
    #expect(minus.transportMinimumRTT == 1.1)
    #expect(minus.transportRTTVariance == 1.2)
    #expect(minus.receivedApplicationByteCount == 72)
    #expect(minus.sentApplicationByteCount == 81)

    // &+= operator
    var mut = lhs
    mut &+= rhs
    #expect(mut == plus)

    // &-= operator
    mut = lhs
    mut &-= rhs
    #expect(mut == minus)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("Initialization from Model copies all properties")
  func initFromPersistentModel() throws {
    let pathReport = V1._DataTransferReport.PathReport()
    pathReport.receivedIPPacketCount = 10
    pathReport.sentIPPacketCount = 20
    pathReport.receivedTransportByteCount = 30
    pathReport.receivedTransportDuplicateByteCount = 40
    pathReport.receivedTransportOutOfOrderByteCount = 50
    pathReport.sentTransportByteCount = 60
    pathReport.retransmittedTransportByteCount = 70
    pathReport.transportSmoothedRTT = 80
    pathReport.transportMinimumRTT = 90
    pathReport.transportRTTVariance = 100
    pathReport.receivedApplicationByteCount = 110
    pathReport.sentApplicationByteCount = 12

    let model = V1._DataTransferReport()
    model._duration = 1.5
    model.aggregatePathReport = pathReport
    model.pathReport = pathReport

    let report = DataTransferReport(persistentModel: model)
    #expect(report._duration == 1.5)
    #expect(report.aggregatePathReport == .init())
    #expect(report.pathReport == .init())
  }
}
