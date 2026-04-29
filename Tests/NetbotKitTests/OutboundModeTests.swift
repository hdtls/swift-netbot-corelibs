// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Preference
import Testing

@testable import NetbotKit

@Suite struct OutboundModeTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: zip(OutboundMode.allCases, ["direct-outbound", "global-proxy", "rule-based"]))
  func rawRepresentableConformance(_ mode: OutboundMode, _ rawValue: String) {
    #expect(mode.rawValue == rawValue)
    #expect(OutboundMode(rawValue: rawValue) == mode)
    #expect(OutboundMode(rawValue: "unknown") == nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(OutboundMode.allCases == [.direct, .globalProxy, .ruleBased])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: zip(OutboundMode.allCases, ["direct-outbound", "global-proxy", "rule-based"]))
  func preferenceRepresentableConformance(_ mode: OutboundMode, _ preferenceValue: String) {
    #expect(mode.preferenceValue as? String == preferenceValue)
    #expect(OutboundMode(preferenceValue: preferenceValue) == mode)
  }
}
