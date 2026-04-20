// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NEAddressProcessing
import NetbotLiteData
import Testing

@testable import NetbotLite

@Suite struct ForwardingRuleTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func finalForwardingRule() {
    let r = _FinalForwardingRule()
    #expect(!r.requireIPAddress)
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
