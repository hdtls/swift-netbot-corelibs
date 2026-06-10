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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValues() async throws {
    let source = V1._DataTransferReport()
    #expect(source.duration == .zero)
    #expect(source.durationFormatted == "0ms")
    #expect(source.pathReport == nil)
    #expect(source.aggregatePathReport == nil)
    #expect(source.pathReportFormatted == .init())
    #expect(source.aggregatePathReportFormatted == .init())
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func mergeValues() throws {
    let model = V1._DataTransferReport()
    model.duration = .seconds(1)
    model.aggregatePathReport = .init()
    model.pathReport = .init()

    let report = DataTransferReport(
      duration: .seconds(99),
      aggregatePathReport: .init(receivedApplicationByteCount: 101),
      pathReport: .init(sentApplicationByteCount: 202)
    )
    model.mergeValues(report)
    #expect(model.duration == .seconds(99))
    #expect(model.aggregatePathReport?.receivedApplicationByteCount == 0)
    #expect(model.pathReport?.sentApplicationByteCount == 0)
    #expect(model.aggregatePathReportFormatted.receivedApplicationByteCount == "101 bytes")
    #expect(model.pathReportFormatted.sentApplicationByteCount == "202 bytes")
  }
}

#if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
  import SwiftData

  extension V1_DataTransferReportTests {

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1._DataTransferReport.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      let data = DataTransferReport(duration: .seconds(1))

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
