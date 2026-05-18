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
import NetbotLiteData
import Testing

@testable import NetbotDashboard

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

struct PrettyPrintedTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func formattedConnectionForwardProtocol() {
    let model = Connection.Model()
    #expect(model.forwardingReport == nil)
    #expect(model.forwardProtocolFormatted == "FINAL (*)")

    model.forwardingReport = .init()
    #expect(model.forwardProtocolFormatted == "DIRECT (*)")

    model.forwardingReport?.forwardingRule = "DOMAIN-SUFFIX test.com"
    #expect(model.forwardProtocolFormatted == "DIRECT (DOMAIN-SUFFIX test.com)")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func connectionProtocolName() {
    let model = Connection.Model()
    #expect(model.protocolName == "TCP")

    model.currentRequest = .init()
    model.currentRequest?.httpRequest = .init(
      method: .get, scheme: "https", authority: nil, path: nil)
    #expect(model.protocolName == "HTTPS")

    model.currentRequest?.httpRequest = .init(method: .get, scheme: nil, authority: nil, path: nil)
    #expect(model.protocolName == "HTTP")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: zip(Connection.State.allCases, [true, true, false, false, false]))
  func connectionIsActive(state: Connection.State, isActive: Bool) {
    let model = Connection.Model()
    model.state = state
    #expect(model.isActive == isActive)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func dataFormatted() {
    var data = Data()
    #expect(data.formatted() == "No Data".localizedCapitalized)

    data.append(contentsOf: [72, 69, 76, 76, 79, 32, 87, 79, 82, 76, 68, 33, 33, 33])
    #expect(data.formatted() == "HELLO WORLD!!!")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func responseFormatted() {
    let response = HTTPResponse(
      status: .ok,
      headerFields: [.contentType: "text/plain; charset=utf-8", .contentLength: "2"]
    )

    let formatted = """
      HTTP/1.1 200 OK
      Content-Type: text/plain; charset=utf-8
      Content-Length: 2
      """
    #expect(response.formatted() == formatted)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func reponseContentTypeCheck() {
    let response = Response.Model()
    #expect(!response.isImage)
    #expect(!response.isText)
    #expect(!response.isForm)
    #expect(!response.isJSON)

    response.httpResponse = HTTPResponse(status: .ok, headerFields: [.accessControlMaxAge: "0"])
    #expect(!response.isImage)
    #expect(!response.isText)
    #expect(!response.isForm)
    #expect(!response.isJSON)

    response.httpResponse = HTTPResponse(
      status: .ok,
      headerFields: [.contentType: "image/png"]
    )
    #expect(response.isImage)
    #expect(!response.isText)
    #expect(!response.isForm)
    #expect(!response.isJSON)

    response.httpResponse?.headerFields = [.contentType: "text/plain"]
    #expect(!response.isImage)
    #expect(response.isText)
    #expect(!response.isForm)
    #expect(!response.isJSON)

    response.httpResponse?.headerFields = [.contentType: "multipart/form-data"]
    #expect(!response.isImage)
    #expect(!response.isText)
    #expect(response.isForm)
    #expect(!response.isJSON)

    response.httpResponse?.headerFields = [.contentType: "application/x-www-form-urlencoded"]
    #expect(!response.isImage)
    #expect(!response.isText)
    #expect(response.isForm)
    #expect(!response.isJSON)

    response.httpResponse?.headerFields = [.contentType: "application/json"]
    #expect(!response.isImage)
    #expect(!response.isText)
    #expect(!response.isForm)
    #expect(response.isJSON)
  }
}
