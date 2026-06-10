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

@Suite struct V1_ProcessReportTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValues() async throws {
    let report = V1._ProcessReport()
    #expect(report.processIdentifier == nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  func mergeValues() throws {
    let model = V1._ProcessReport()
    model.processIdentifier = 1
    let report = ProcessReport(processIdentifier: 99999)
    model.mergeValues(report)
    #expect(model.processIdentifier == 99999)
  }
}

#if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
  import SwiftData

  extension V1_ProcessReportTests {

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1._ProcessReport.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      let data = ProcessReport(
        processIdentifier: 63528,
        program: nil
      )

      let model = V1._ProcessReport()
      model.mergeValues(data)
      modelContext.insert(model)

      let fetched = try modelContext.fetch(FetchDescriptor<V1._ProcessReport>()).first
      let persistentModel = try #require(fetched)
      let result = ProcessReport(persistentModel: persistentModel)
      #expect(result == data)
    }
  }
#endif
