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

struct CapabilityFlagsTests {

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      CapabilityFlags.allCases,
      ["Enable HTTP Capture", "Enable HTTPS MitM", "Enable Rewrite", "Enable Scripting"]
    )
  )
  func localizedName(_ capability: CapabilityFlags, _ localizedName: String) {
    #expect(capability.localizedName == localizedName)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func caseIterableConformance() {
    #expect(CapabilityFlags.allCases == [.httpCapture, .httpsDecryption, .rewrite, .scripting])
  }

  @available(SwiftStdlib 6.0, *)
  @Test func equalityAndHashing() async throws {
    let capability1 = CapabilityFlags.httpCapture
    let capability2 = CapabilityFlags.httpCapture
    let capability3 = CapabilityFlags.httpsDecryption
    let capability4 = CapabilityFlags.rewrite
    let capability5 = CapabilityFlags.scripting

    #expect(capability1 == capability2)
    #expect(capability1 != capability3)

    let set = Set([capability1, capability2, capability3, capability4, capability5])
    #expect(set.count == 4)
  }
}
