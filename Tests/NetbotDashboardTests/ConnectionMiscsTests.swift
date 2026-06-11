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
import NetbotLiteData
import Testing

struct ConnectionMiscsTests {

  @available(SwiftStdlib 6.0, *)
  @Test func localizedConnectionStateName() {
    #expect(Connection.State.establishing.localizedName == "Establishing")
    #expect(Connection.State.active.localizedName == "Active")
    #expect(Connection.State.completed.localizedName == "Completed")
    #expect(Connection.State.failed.localizedName == "Failed")
    #expect(Connection.State.cancelled.localizedName == "Cancelled")
  }
}
