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

@Suite struct FirstRangeTests {

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
