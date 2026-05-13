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

@testable import NetbotFrontend

struct FirstRangeTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: [
      (["[A]"], 1...1),
      (["", "[A]"], 2...2),
      (["", "[A]", "[B]"], 2...2),
      (["", "[A]", ""], 2...2),
      (["", "[A]", "", ""], 2...2),
      (["", "[A]", "", "[B]"], 2...2),
      (["", "[A]", "", "", "", "[B]"], 2...2),
      (["", "[A]", "", "A", "", "[B]"], 2...4),
      (["", "[A]", "", "A", "", "", "[B]"], 2...4),
    ]
  )
  func firstRange(_ source: [Substring], expected: ClosedRange<Int>) {
    #expect([].firstRange(match: /\[A]/) == nil)
    #expect([""].firstRange(match: /\[A]/) == nil)
    #expect(source.firstRange(match: /\[A]/) == expected)
  }
}
