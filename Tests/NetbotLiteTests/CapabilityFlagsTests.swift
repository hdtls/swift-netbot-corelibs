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

@testable import NetbotLite

@Suite struct CapabilityFlagsTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("Individual flags have correct raw values")
  func individualRawValues() {
    #expect(CapabilityFlags.httpCapture.rawValue == 1)
    #expect(CapabilityFlags.httpsDecryption.rawValue == 2)
    #expect(CapabilityFlags.rewrite.rawValue == 4)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("OptionSet contains and union logic")
  func combinations() {
    let all: CapabilityFlags = [.httpCapture, .httpsDecryption, .rewrite]
    #expect(all.contains(.httpCapture))
    #expect(all.contains(.httpsDecryption))
    #expect(all.contains(.rewrite))
    #expect(!all.contains(CapabilityFlags(rawValue: 8)))

    let some: CapabilityFlags = [.httpCapture, .rewrite]
    #expect(some.contains(.httpCapture))
    #expect(!some.contains(.httpsDecryption))
    #expect(some.contains(.rewrite))
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("Hashable and equality")
  func hashableAndEquality() {
    let a: CapabilityFlags = [.httpCapture, .httpsDecryption]
    let b: CapabilityFlags = [.httpsDecryption, .httpCapture]
    let c: CapabilityFlags = [.rewrite]
    #expect(a == b)
    #expect(a != c)
    let set: Set<CapabilityFlags> = [a, b, c]
    #expect(set.contains(a))
    #expect(set.contains(c))
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("Empty flags")
  func emptyFlags() {
    let empty = CapabilityFlags()
    #expect(empty.rawValue == 0)
    #expect(!empty.contains(.httpCapture))
  }
}
