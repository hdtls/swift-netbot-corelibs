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

@Suite struct ConnectionFilterTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hashable() async throws {
    let h1 = ConnectionFilter.hostname("swift.org")
    let h2 = h1
    let h3 = ConnectionFilter.client("ssh")

    let set = Set([h1, h2, h3])
    #expect(set.count == 2, "Set should contain only 2 unique filters")
  }
}
