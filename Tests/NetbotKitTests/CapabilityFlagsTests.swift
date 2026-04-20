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

import Testing

@testable import NetbotKit

@Suite struct CapabilityFlagsTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      CapabilityFlags.allCases,
      ["Enable HTTP Capture", "Enable HTTPS MitM", "Enable Rewrite", "Enable Scripting"]
    )
  )
  func localizedName(_ capability: CapabilityFlags, _ localizedName: String) {
    #expect(capability.localizedName == localizedName)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(CapabilityFlags.allCases == [.httpCapture, .httpsDecryption, .rewrite, .scripting])
  }
}
