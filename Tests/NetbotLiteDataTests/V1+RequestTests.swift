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
import NEAddressProcessing
import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct V1_RequestTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValues() async throws {
    let source = V1._Request()
    #expect(source.httpRequest == nil)
    #expect(source.address == nil)
    #expect(source.hostname == nil)
    #expect(source.absoluteURLString == nil)
    #expect(source.body == nil)
  }

  #if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func httpRequestCodableConformance() async throws {
      let httpRequest = HTTPRequest(
        method: .get, scheme: "https", authority: "swift.org:443", path: nil)
      let request = V1._HTTPRequest(httpRequest: httpRequest)
      let data = try JSONEncoder().encode(request)
      let result = try JSONDecoder().decode(V1._HTTPRequest.self, from: data)
      #expect(request == result)
    }
  #endif

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createRequestWithAddress() async throws {
    let source = V1._Request()
    source.address = .hostPort(host: "swift.org", port: 443)
    #expect(source.httpRequest == nil)
    #expect(source.address == .hostPort(host: "swift.org", port: 443))
    #expect(source.body == nil)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func createRequestWithHTTPRequest() async throws {
    let httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    let source = V1._Request()
    source.httpRequest = httpRequest
    #expect(source.httpRequest == httpRequest)
    //      #expect(source.address == .hostPort(host: "swift.org", port: 443))
    #expect(source.body == nil)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func setHTTPRequest() async throws {
    let httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)

    let source = V1._Request()
    source.address = .hostPort(host: "swift.org", port: 443)
    source.httpRequest = httpRequest
    #expect(source.httpRequest == httpRequest)

    source.httpRequest = nil
    #expect(source.httpRequest == nil)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func setAddress() async throws {
    let address = Address.hostPort(host: "swift.org", port: 443)
    let source = V1._Request()
    source.address = address
    #expect(source.address == address)

    source.address = nil
    #expect(source.address == nil)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func mergeValues() async throws {
    var httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    var data = Request(httpRequest: httpRequest)
    data.body = Data([0])

    let source = V1._Request()
    source.mergeValues(data)

    #expect(source.httpRequest == httpRequest)
    #expect(source.address == .hostPort(host: "swift.org", port: 443))
    #expect(source.hostname == "swift.org")
    #expect(source.absoluteURLString == "swift.org")
    #expect(source.body == Data([0]))

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
