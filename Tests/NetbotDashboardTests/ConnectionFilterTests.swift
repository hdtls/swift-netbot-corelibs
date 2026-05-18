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

import Testing

@testable import NetbotDashboard

struct ConnectionFilterTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func equalityAndHashing() async throws {
    let h1 = ConnectionFilter.hostname("swift.org")
    let h2 = ConnectionFilter.hostname("swift.org")
    let h3 = ConnectionFilter.client("ssh")

    #expect(h1 == h2)
    #expect(h1 != h3)

    let set = Set([h1, h2, h3])
    #expect(set.count == 2, "Set should contain only 2 unique filters")
  }
}
