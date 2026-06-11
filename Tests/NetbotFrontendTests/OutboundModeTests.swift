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

import Preference
import Testing

@testable import NetbotFrontend

struct OutboundModeTests {

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      OutboundMode.allCases,
      [
        "All requests will be sent directly", "All requests will be forwarded to a proxy server",
        "All requests will be forwarded base on rule system",
      ]))
  func localizedDescription(_ mode: OutboundMode, _ description: String) {
    #expect(mode.localizedDescription == description)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: zip(OutboundMode.allCases, ["direct-outbound", "global-proxy", "rule-based"]))
  func rawRepresentableConformance(_ mode: OutboundMode, _ rawValue: String) {
    #expect(mode.rawValue == rawValue)
    #expect(OutboundMode(rawValue: rawValue) == mode)
    #expect(OutboundMode(rawValue: "unknown") == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func caseIterableConformance() {
    #expect(OutboundMode.allCases == [.direct, .globalProxy, .ruleBased])
  }

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: zip(OutboundMode.allCases, ["direct-outbound", "global-proxy", "rule-based"]))
  func preferenceRepresentableConformance(_ mode: OutboundMode, _ preferenceValue: String) {
    #expect(mode.preferenceValue as? String == preferenceValue)
    #expect(OutboundMode(preferenceValue: preferenceValue) == mode)
  }
}
