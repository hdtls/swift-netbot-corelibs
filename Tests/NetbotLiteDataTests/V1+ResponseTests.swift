// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2023 Junfeng Zhang and the Netbot project authors
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

@Suite struct V1_ResponseTests {

  @available(SwiftStdlib 5.9, *)
  @Test func propertyInitialValues() async throws {
    let source = V1._Response()
    #expect(source.httpResponse == nil)
    #expect(source.body == nil)
  }

  #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
    @available(SwiftStdlib 5.9, *)
    @Test func httpResponseCodableConformance() async throws {
      let httpResponse = HTTPResponse(status: .ok)
      let response = V1._HTTPResponse(httpResponse: httpResponse)
      let data = try JSONEncoder().encode(response)
      let result = try JSONDecoder().decode(V1._HTTPResponse.self, from: data)
      #expect(response == result)
    }
  #endif

  @available(SwiftStdlib 5.9, *)
  @Test func setHTTPResponse() async throws {
    let httpResponse = HTTPResponse(status: .ok)

    let source = V1._Response()
    source.httpResponse = httpResponse
    #expect(source.httpResponse == httpResponse)

    source.httpResponse = nil
    #expect(source.httpResponse == nil)
  }

  @available(SwiftStdlib 5.9, *)
  @Test func mergeValues() async throws {
    let httpResponse = HTTPResponse(status: .ok)
    var data = Response(httpResponse: httpResponse)
    data.body = Data([0])

    let source = V1._Response()
    source.mergeValues(data)

    #expect(source.httpResponse == httpResponse)
    #expect(source.body == Data([0]))
  }
}
