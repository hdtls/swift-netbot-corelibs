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
import NIOCore
import NIOEmbedded
import NIOHTTP1
import NIOHTTPTypesHTTP1
import NetbotLiteData
import Testing

@testable import NetbotLite

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

struct InMemoryHTTPCaptureTests {

  #if swift(>=6.2)
    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func unsupportedHeadT() async throws {
      await #expect(processExitsWith: .failure) {
        _ = InMemoryHTTPCapture<Int>(connection: .init(), captureFilters: [])
      }
    }
  #endif

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func onHTTPRequest() async throws {
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.currentRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.tls = true
    let capture = InMemoryHTTPCapture<HTTPRequestHead>(connection: connection, captureFilters: [])
    let channel = await NIOAsyncTestingChannel(handler: capture)
    let head = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/test")
    try await channel.writeInbound(HTTPPart<HTTPRequestHead, ByteBuffer>.head(head))

    let expected = Request(httpRequest: try .init(head, secure: connection.tls, splitCookie: false))
    #expect(connection.currentRequest == expected)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func onHTTPRequestBody() async throws {
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.currentRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.tls = true
    let capture = InMemoryHTTPCapture<HTTPRequestHead>(connection: connection, captureFilters: [])
    let channel = await NIOAsyncTestingChannel(handler: capture)

    let partialBody = ByteBuffer(bytes: [0x01, 0x02, 0x03])
    try await channel.writeInbound(HTTPPart<HTTPRequestHead, ByteBuffer>.body(partialBody))

    #expect(connection.currentRequest?.body == Data(Array(buffer: partialBody)))

    try await channel.writeInbound(HTTPPart<HTTPRequestHead, ByteBuffer>.body(partialBody))

    #expect(connection.currentRequest?.body == Data([0x01, 0x02, 0x03, 0x01, 0x02, 0x03]))
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func onHTTPRequestEnd() async throws {
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.currentRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.tls = true
    let capture = InMemoryHTTPCapture<HTTPRequestHead>(connection: connection, captureFilters: [])
    let channel = await NIOAsyncTestingChannel(handler: capture)
    try await channel.writeInbound(HTTPPart<HTTPRequestHead, ByteBuffer>.end(nil))
    #expect(connection.currentRequest?.trailers == nil)

    try await channel.writeInbound(
      HTTPPart<HTTPRequestHead, ByteBuffer>.end(["Server-Timing": "custom-metric;dur=123.4"]))
    #expect(
      connection.currentRequest?.trailers == [
        HTTPField.Name("Server-Timing")!: "custom-metric;dur=123.4"
      ]
    )
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func onHTTPResponse() async throws {
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.currentRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.tls = true
    let capture = InMemoryHTTPCapture<HTTPResponseHead>(connection: connection, captureFilters: [])
    let channel = await NIOAsyncTestingChannel(handler: capture)
    let head = HTTPResponseHead(version: .http1_1, status: .ok)
    try await channel.writeInbound(HTTPPart<HTTPResponseHead, ByteBuffer>.head(head))

    let expected = Response(httpResponse: .init(status: .ok))
    #expect(connection.response == expected)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func onHTTPResponseBody() async throws {
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.currentRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.response = .init()
    let capture = InMemoryHTTPCapture<HTTPResponseHead>(connection: connection, captureFilters: [])
    let channel = await NIOAsyncTestingChannel(handler: capture)

    let partialBody = ByteBuffer(bytes: [0x01, 0x02, 0x03])
    try await channel.writeInbound(HTTPPart<HTTPResponseHead, ByteBuffer>.body(partialBody))

    #expect(connection.response?.body == Data(Array(buffer: partialBody)))

    try await channel.writeInbound(HTTPPart<HTTPResponseHead, ByteBuffer>.body(partialBody))

    #expect(connection.response?.body == Data([0x01, 0x02, 0x03, 0x01, 0x02, 0x03]))
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func onHTTPResponseEnd() async throws {
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.currentRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.response = .init()
    let capture = InMemoryHTTPCapture<HTTPResponseHead>(connection: connection, captureFilters: [])
    let channel = await NIOAsyncTestingChannel(handler: capture)
    try await channel.writeInbound(HTTPPart<HTTPResponseHead, ByteBuffer>.end(nil))
    #expect(connection.response?.trailers == nil)

    try await channel.writeInbound(
      HTTPPart<HTTPResponseHead, ByteBuffer>.end(["Server-Timing": "custom-metric;dur=123.4"]))
    #expect(
      connection.response?.trailers == [HTTPField.Name("Server-Timing")!: "custom-metric;dur=123.4"]
    )
  }
}
