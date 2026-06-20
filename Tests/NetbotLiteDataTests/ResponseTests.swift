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

@Suite struct ResponseTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValues() async throws {
    let httpResponse = HTTPResponse(status: .ok)
    var source = Response(httpResponse: httpResponse)
    #expect(source.httpResponse == httpResponse)
    #expect(source.body == nil)
    #expect(source.trailerHTTPFields == nil)

    source = Response()
    #expect(source.httpResponse == nil)
    #expect(source.body == nil)
    #expect(source.trailerHTTPFields == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func hashableConformance() async throws {
    let response = Response()
    let expected = response
    #expect(response == expected)

    let responses = Set<Response>([response, expected])
    #expect(responses == [response])
  }

  @available(SwiftStdlib 6.0, *)
  @Test func codableConformance() async throws {
    var response = Response()
    var data = try JSONEncoder().encode(response)
    var result = try JSONDecoder().decode(Response.self, from: data)
    #expect(response == result)

    let httpResponse = HTTPResponse(status: .ok)
    response = Response(httpResponse: httpResponse)
    data = try JSONEncoder().encode(response)
    result = try JSONDecoder().decode(Response.self, from: data)
    #expect(response == result)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func persistentModel() {
    let source = Response.Model.self
    #expect(source == V1.Response.self)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func initializeResponseFromPersistentModel() async throws {
    let persistentModel = Response.Model()
    persistentModel.httpResponse = .init(status: .ok)
    persistentModel.trailerHTTPFields = [.init("Digest")!: "sha-256=abc123..."]

    let response = Response(persistentModel: persistentModel)
    #expect(response.httpResponse == .init(status: .ok))
    #expect(response.body == persistentModel.body)
    #expect(response.trailerHTTPFields == persistentModel.trailerHTTPFields)
  }
}
