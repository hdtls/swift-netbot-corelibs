//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import Testing

@testable import NetbotKit

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct DateRawRepresentableTests {

  @Test func create() {
    let expected = Date()
    #expect(Date(rawValue: expected.rawValue) == expected)
  }

  @Test func createWithInvalidRawValue() {
    #expect(Date(rawValue: "") == nil)
  }

  @Test func rawValue() {
    let date = Date()
    #expect(date.rawValue == date.timeIntervalSinceReferenceDate.description)
  }
}
