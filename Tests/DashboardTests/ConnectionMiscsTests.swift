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

@Suite struct ConnectionMiscsTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func stateLocalizedName() {
    #expect(Connection.State.establishing.localizedName == "Establishing")
    #expect(Connection.State.active.localizedName == "Active")
    #expect(Connection.State.completed.localizedName == "Completed")
    #expect(Connection.State.failed.localizedName == "Failed")
    #expect(Connection.State.cancelled.localizedName == "Cancelled")
  }
}
