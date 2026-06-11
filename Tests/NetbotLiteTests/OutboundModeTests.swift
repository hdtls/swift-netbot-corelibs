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

import NetbotLite
import Testing

struct OutboundModeTests {

  @available(SwiftStdlib 6.0, *)
  @Test func rawRepresentable() {
    #expect(OutboundMode.direct.rawValue == "direct-outbound")
    #expect(OutboundMode.globalProxy.rawValue == "global-proxy")
    #expect(OutboundMode.ruleBased.rawValue == "rule-based")
    #expect(OutboundMode(rawValue: "direct-outbound") == OutboundMode.direct)
    #expect(OutboundMode(rawValue: "global-proxy") == OutboundMode.globalProxy)
    #expect(OutboundMode(rawValue: "rule-based") == OutboundMode.ruleBased)
    #expect(OutboundMode(rawValue: "unknown") == nil)
  }
}
