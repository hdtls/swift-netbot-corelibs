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

import NEAddressProcessing
import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct V1_ForwardingReportTests {

  @available(SwiftStdlib 6.0, *)
  @Test func persistentModelTypealias() {
    #expect(ForwardingReport.Model.self == V1.ForwardingReport.self)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mergeValues() {
    let model = V1.ForwardingReport()

    let earliestBeginDate = Date.now
    let data = ForwardingReport(
      earliestBeginDate: earliestBeginDate,
      duration: .seconds(13.5),
      forwardProtocol: "REJECT",
      forwardingRule: "FINAL"
    )

    model.mergeValues(data)
    #expect(model.earliestBeginDate == earliestBeginDate)
    #expect(model.duration == .seconds(13.5))
    #expect(model.forwardProtocol == "REJECT")
    #expect(model.forwardingRule == "FINAL")
  }
}

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  extension V1_ForwardingReportTests {

    @available(SwiftStdlib 6.0, *)
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1.ForwardingReport.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      let data = ForwardingReport(
        earliestBeginDate: .now,
        duration: .seconds(1),
        forwardProtocol: "DIRECT",
        forwardingRule: "DOMAIN-SUFIX example.com"
      )

      let model = V1.ForwardingReport()
      model.mergeValues(data)
      modelContext.insert(model)

      let fetched = try modelContext.fetch(FetchDescriptor<V1.ForwardingReport>()).first
      let persistentModel = try #require(fetched)
      let result = ForwardingReport(persistentModel: persistentModel)
      #expect(result == data)
    }
  }
#endif
