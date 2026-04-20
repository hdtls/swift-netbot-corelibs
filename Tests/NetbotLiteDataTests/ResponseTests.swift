// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import HTTPTypes
import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct ResponseTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValues() async throws {
    let httpResponse = HTTPResponse(status: .ok)
    var source = Response(httpResponse: httpResponse)
    #expect(source.httpResponse == httpResponse)
    #expect(source.body == nil)

    source = Response()
    #expect(source.httpResponse == nil)
    #expect(source.body == nil)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hashableConformance() async throws {
    let response = Response()
    let expected = response
    #expect(response == expected)

    let responses = Set<Response>([response, expected])
    #expect(responses == [response])
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func persistentModel() {
    let source = Response.Model.self
    #expect(source == V1._Response.self)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func initializeResponseFromPersistentModel() async throws {
    let persistentModel = V1._Response()
    persistentModel.httpResponse = .init(status: .ok)
    let response = Response(persistentModel: persistentModel)
    #expect(response == Response(httpResponse: .init(status: .ok)))
  }
}
