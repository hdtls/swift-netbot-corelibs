// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Testing

@testable import Dashboard

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

@Suite struct PrettyPrintedTests {

  @Test func forwardProtocolFormatted() {
    let model = Connection.Model()
    #expect(model.forwardingReport == nil)
    #expect(model.forwardProtocolFormatted == "FINAL (*)")

    model.forwardingReport = .init()
    #expect(model.forwardProtocolFormatted == "DIRECT (*)")

    model.forwardingReport?.forwardingRule = "DOMAIN-SUFFIX test.com"
    #expect(model.forwardProtocolFormatted == "DIRECT (DOMAIN-SUFFIX test.com)")
  }

  @Test func protocolName() {
    let model = Connection.Model()
    #expect(model.protocolName == "TCP")

    model.currentRequest = .init()
    model.currentRequest?.httpRequest = .init(
      method: .get, scheme: "https", authority: nil, path: nil)
    #expect(model.protocolName == "HTTPS")

    model.currentRequest?.httpRequest = .init(method: .get, scheme: nil, authority: nil, path: nil)
    #expect(model.protocolName == "TCP")
  }

  @Test func isActive() {
    let model = Connection.Model()
    #expect(model.isActive)

    model.state = .completed
    #expect(!model.isActive)

    model.state = .establishing
    #expect(model.isActive)

    model.state = .failed
    #expect(!model.isActive)

    model.state = .active
    #expect(model.isActive)

    model.state = .cancelled
    #expect(!model.isActive)
  }

  @Test func dataFormatted() {
    let data = Data()
    #expect(data.formatted() == "No Data".localizedCapitalized)
  }
}
