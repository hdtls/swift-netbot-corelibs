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
  import FoundationInternationalization
#else
  import Foundation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData
#endif

@Suite struct V1_ConnectionTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValues() {
    let connection = V1._Connection()
    #expect(connection.taskIdentifier == 0)
    #expect(connection.originalRequest == nil)
    #expect(connection.currentRequest == nil)
    #expect(connection.response == nil)
    #expect(connection.earliestBeginDateFormatted != "")
    #expect(connection.taskDescription == "")
    #expect(connection.tls == false)
    #expect(connection.state == .establishing)
    #expect(connection.establishmentReport == nil)
    #expect(connection.forwardingReport == nil)
    #expect(connection.dataTransferReport == nil)
    #expect(connection.processReport == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func connectionIdentifiable() {
    #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
      let connection = V1._Connection()
      #expect(connection.id == connection.persistentModelID)
    #else
      let connection = V1._Connection()
      #expect(connection.persistentModelID == connection.taskIdentifier)
      #expect(connection.id == connection.persistentModelID)
    #endif
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mergeValues() {
    let date = Date()
    let data = Connection(taskIdentifier: 55)
    data.earliestBeginDate = date
    data.duration = .seconds(1000)
    data.taskDescription = "descA"
    data.tls = false
    data.state = .active
    data.forwardingReport = .init(
      earliestBeginDate: .now,
      duration: .seconds(1),
      forwardProtocol: "FINAL",
      forwardingRule: nil
    )

    let connection = V1._Connection()
    connection.taskIdentifier = 1
    connection.earliestBeginDate = date
    connection.taskDescription = "descB"
    connection.tls = true
    connection.state = .completed
    connection.forwardingReport = .init()

    connection.mergeValues(data)

    #expect(connection.taskIdentifier == 55)
    #expect(connection.earliestBeginDate == date)
    #expect(
      connection.earliestBeginDateFormatted == date.formatted(.dateTime.hour().minute().second())
    )
    #expect(connection.duration == .seconds(1000))
    #expect(connection.taskDescription == "descA")
    #expect(connection.tls == false)
    #expect(connection.state == .active)
  }
}

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  extension V1_ConnectionTests {

    @available(SwiftStdlib 6.0, *)
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1._Connection.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      let data = Connection()

      let model = V1._Connection()
      model.mergeValues(data)
      modelContext.insert(model)

      #expect(throws: Never.self) {
        let fetched = try modelContext.fetch(FetchDescriptor<V1._Connection>()).first
        #expect(fetched != nil)
      }
    }
  }
#endif
