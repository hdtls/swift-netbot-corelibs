// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2025-2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import NetbotLite
import Testing

@testable import Netbot

@Suite struct OutboundModeTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      [OutboundMode.direct, .globalProxy, .ruleBased],
      ["Direct Outbound", "Global Proxy", "Rule-based Proxy"]))
  func localizedName(_ mode: OutboundMode, _ localizedName: String) {
    #expect(mode.localizedName == localizedName)
  }
}
