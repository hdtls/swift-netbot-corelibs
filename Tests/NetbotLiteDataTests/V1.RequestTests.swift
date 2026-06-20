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
import NEAddressProcessing
import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct V1_RequestTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValues() async throws {
    let source = V1.Request()
    #expect(source.httpRequest == nil)
    #expect(source.address == nil)
    #expect(source.hostname == nil)
    #expect(source.absoluteURLString == nil)
    #expect(source.body == nil)
    #expect(source.trailerHTTPFields == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func createRequestWithAddress() async throws {
    let source = V1.Request()
    source.address = .hostPort(host: "swift.org", port: 443)
    #expect(source.httpRequest == nil)
    #expect(source.address == .hostPort(host: "swift.org", port: 443))
    #expect(source.body == nil)
    #expect(source.trailerHTTPFields == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func createRequestWithHTTPRequest() async throws {
    let httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    let source = V1.Request()
    source.httpRequest = httpRequest
    #expect(source.httpRequest == httpRequest)
    //      #expect(source.address == .hostPort(host: "swift.org", port: 443))
    #expect(source.body == nil)
    #expect(source.trailerHTTPFields == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func setHTTPRequest() async throws {
    let httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)

    let source = V1.Request()
    source.address = .hostPort(host: "swift.org", port: 443)
    source.httpRequest = httpRequest
    #expect(source.httpRequest == httpRequest)

    source.httpRequest = nil
    #expect(source.httpRequest == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func setAddress() async throws {
    let address = Address.hostPort(host: "swift.org", port: 443)
    let source = V1.Request()
    source.address = address
    #expect(source.address == address)

    source.address = nil
    #expect(source.address == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mergeValues() async throws {
    var httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    var data = Request(httpRequest: httpRequest)
    data.body = Data([0])
    data.trailerHTTPFields = [.init("Digest")!: "sha-256=abc123..."]

    let source = V1.Request()
    source.mergeValues(data)

    #expect(source.httpRequest == httpRequest)
    #expect(source.address == .hostPort(host: "swift.org", port: 443))
    #expect(source.hostname == "swift.org")
    #expect(source.absoluteURLString == "swift.org")
    #expect(source.body == Data([0]))
    #expect(source.trailerHTTPFields == data.trailerHTTPFields)

    httpRequest.authority = "example.com:8080"
    data.httpRequest = httpRequest
    source.mergeValues(data)

    #expect(source.absoluteURLString == "example.com:8080")

    httpRequest.authority = "example.com:8080"
    httpRequest.path = "/path"
    data.httpRequest = httpRequest
    source.mergeValues(data)

    #expect(source.absoluteURLString == "example.com:8080/path")
  }
}

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  extension V1_RequestTests {

    @available(SwiftStdlib 6.0, *)
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1.Request.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      var data = Request(
        httpRequest: .init(
          method: .get,
          scheme: "https",
          authority: "example.com",
          path: "/posts",
          headerFields: [.connection: "keep-alive"]
        )
      )
      data.body = Data([0])
      data.trailerHTTPFields = [.init("Digest")!: "sha-256=abc123..."]

      let model = V1.Request()
      model.mergeValues(data)
      modelContext.insert(model)

      let fetched = try modelContext.fetch(FetchDescriptor<V1.Request>()).first
      let persistentModel = try #require(fetched)
      let result = Request(persistentModel: persistentModel)
      #expect(result == data)
    }
  }
#endif
