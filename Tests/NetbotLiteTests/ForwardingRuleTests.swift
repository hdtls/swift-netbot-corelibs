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

import NEAddressProcessing
import NetbotLiteData
import Testing

@testable import NetbotLite

@Suite struct ForwardingRuleTests {

  @available(SwiftStdlib 6.0, *)
  @Test func finalForwardingRule() {
    let r = _FinalForwardingRule()
    #expect((r.forwardProtocol as? ForwardProtocolDirect) != nil)
    #expect(r.description == "FINAL")
    #expect(throws: Never.self) {
      let originalRequest = Request(address: .hostPort(host: "127.0.0.1", port: 80))
      let connection = Connection()
      connection.originalRequest = originalRequest
      let result = try r.predicate(connection)
      #expect(result)
    }
  }
}
