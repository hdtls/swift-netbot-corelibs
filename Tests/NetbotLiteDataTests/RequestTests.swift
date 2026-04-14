//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import HTTPTypes
import NEAddressProcessing
import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct RequestTests {

  @available(SwiftStdlib 5.3, *)
  @Test func hostOfHTTPRequest() {
    var source = HTTPRequest(method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    #expect(source.host() == "swift.org")
    #expect(source.host(percentEncoded: false) == "swift.org")

    source = HTTPRequest(method: .get, scheme: "https", authority: nil, path: nil)
    #expect(source.host() == nil)
    #expect(source.host(percentEncoded: false) == nil)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func portOfHTTPRequest() {
    var source = HTTPRequest(method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    #expect(source.port == 443)

    source = HTTPRequest(method: .get, scheme: "https", authority: "swift.org", path: nil)
    #expect(source.port == nil)

    source = HTTPRequest(method: .get, scheme: "https", authority: nil, path: nil)
    #expect(source.port == nil)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func addressOfHTTPRequest() async throws {
    var source = HTTPRequest(method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    #expect(source.address == .hostPort(host: "swift.org", port: 443))

    source = HTTPRequest(method: .get, scheme: "https", authority: "swift.org", path: nil)
    #expect(source.address == nil)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func propertyInitialValues() async throws {
    let httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    var source = Request(httpRequest: httpRequest)
    #expect(source.httpRequest == httpRequest)
    #expect(source.address == httpRequest.address)
    #expect(source.body == nil)

    source = Request(address: .hostPort(host: "swift.org", port: 443))
    #expect(source.httpRequest == nil)
    #expect(source.address == .hostPort(host: "swift.org", port: 443))
    #expect(source.body == nil)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func hostOfRequest() {
    var source = Request(
      httpRequest: HTTPRequest(
        method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    )
    #expect(source.host() == "swift.org")
    #expect(source.host(percentEncoded: false) == "swift.org")

    source = Request(address: .hostPort(host: "swift.org", port: 443))
    #expect(source.host() == "swift.org")
    #expect(source.host(percentEncoded: false) == "swift.org")

    source = Request(address: .hostPort(host: "swift.org", port: 443))
    #expect(source.host() == "swift.org")
    #expect(source.host(percentEncoded: false) == "swift.org")

    source = Request(address: .unix(path: "/var/tmp/run.socks"))
    #expect(source.host() == nil)
    #expect(source.host(percentEncoded: false) == nil)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func portOfRequest() {
    var source = Request(
      httpRequest: HTTPRequest(
        method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    )
    #expect(source.port == 443)

    source = Request(address: .hostPort(host: "swift.org", port: 443))
    #expect(source.port == 443)

    source = Request(address: .hostPort(host: "swift.org", port: 443))
    #expect(source.port == 443)

    source = Request(address: .unix(path: "/var/tmp/run.sock"))
    #expect(source.port == nil)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func setHTTPRequest() {
    let httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)

    var data = Request(address: .hostPort(host: "127.0.0.1", port: 2213))
    #expect(data.address == .hostPort(host: "127.0.0.1", port: 2213))

    data.httpRequest = httpRequest
    #expect(data.address == .hostPort(host: "swift.org", port: 443))
  }

  @available(SwiftStdlib 5.3, *)
  @Test func hashableConformance() async throws {
    let request = Request(address: .unix(path: "/var/run/tmp.socks"))
    let expected = request
    #expect(request == expected)

    let requests = Set<Request>([request, expected])
    #expect(requests == [request])
  }

  @available(SwiftStdlib 5.3, *)
  @Test func codableConformance() async throws {
    var request = Request(address: .unix(path: "/var/run/tmp.socks"))
    var data = try JSONEncoder().encode(request)
    var result = try JSONDecoder().decode(Request.self, from: data)
    #expect(request == result)

    let httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)
    request = Request(httpRequest: httpRequest)
    data = try JSONEncoder().encode(request)
    result = try JSONDecoder().decode(Request.self, from: data)
    #expect(request == result)
  }

  @available(SwiftStdlib 5.9, *)
  @Test func persistentModel() {
    let source = Request.Model.self
    #expect(source == V1._Request.self)
  }

  @available(SwiftStdlib 5.9, *)
  @Test func initializeRequestFromPersistentModel() async throws {
    let httpRequest = HTTPRequest(
      method: .get, scheme: "https", authority: "swift.org:443", path: nil)

    let source = V1._Request()
    source.httpRequest = httpRequest
    source.address = .hostPort(host: "swift.org", port: 443)
    source.body = Data([0])

    let data = Request(persistentModel: source)

    #expect(data.httpRequest == httpRequest)
    #expect(data.address == .hostPort(host: "swift.org", port: 443))
    #expect(data.body == Data([0]))
  }
}
