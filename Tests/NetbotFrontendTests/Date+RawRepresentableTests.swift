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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

struct DateRawRepresentableTests {

  @available(SwiftStdlib 6.0, *)
  @Test func create() {
    let expected = Date()
    #expect(Date(rawValue: expected.rawValue) == expected)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func createWithInvalidRawValue() {
    #expect(Date(rawValue: "") == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func rawValue() {
    let date = Date()
    #expect(date.rawValue == date.timeIntervalSinceReferenceDate.description)
  }
}
