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

import NetbotDashboard
import NetbotFrontend
import Preference
import Testing

struct CapabilityFlagsTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func preferenceRepresentable() {
    let capability = CapabilityFlags(preferenceValue: 1)
    #expect(capability == .httpCapture)
    #expect(CapabilityFlags.httpCapture.preferenceValue as? Int == 1)
  }
}
