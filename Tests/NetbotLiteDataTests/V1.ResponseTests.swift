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

import HTTPTypes
import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct V1_ResponseTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValues() async throws {
    let source = V1._Response()
    #expect(source.httpResponse == nil)
    #expect(source.body == nil)
    #expect(source.trailerHTTPFields == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func setHTTPResponse() async throws {
    let httpResponse = HTTPResponse(status: .ok)

    let source = V1._Response()
    source.httpResponse = httpResponse
    #expect(source.httpResponse == httpResponse)

    source.httpResponse = nil
    #expect(source.httpResponse == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mergeValues() async throws {
    let httpResponse = HTTPResponse(status: .ok)
    var data = Response(httpResponse: httpResponse)
    data.body = Data([0])
    data.trailerHTTPFields = [.init("Digest")!: "sha-256=abc123..."]

    let source = V1._Response()
    source.mergeValues(data)

    #expect(source.httpResponse == httpResponse)
    #expect(source.body == Data([0]))
    #expect(source.trailerHTTPFields == data.trailerHTTPFields)
  }
}

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  extension V1_ResponseTests {

    @available(SwiftStdlib 6.0, *)
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1._Response.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      var data = Response(httpResponse: .init(status: .ok))
      data.body = Data([0])
      data.trailerHTTPFields = [.init("Digest")!: "sha-256=abc123..."]

      let model = V1._Response()
      model.mergeValues(data)
      modelContext.insert(model)

      let fetched = try modelContext.fetch(FetchDescriptor<V1._Response>()).first
      let persistentModel = try #require(fetched)
      let result = Response(persistentModel: persistentModel)
      #expect(result == data)
    }
  }
#endif
