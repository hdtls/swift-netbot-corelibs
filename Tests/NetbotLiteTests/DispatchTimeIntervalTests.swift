// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2022 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Dispatch
import Testing

@testable import NetbotLite

@Suite struct DispathTimeIntervalTests {

  let t1 = DispatchTime(uptimeNanoseconds: 0)

  #if os(Linux) || os(Windows) || os(Android) || os(OpenBSD)
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      @available(SwiftStdlib 5.3, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    func distanceCalculate() {
      let t2 = DispatchTime(uptimeNanoseconds: 1)
      #expect(t1.distance(to: t2) == .nanoseconds(1))
    }
  #endif

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func prettyPrintSeconds() {
    var t2 = DispatchTimeInterval.seconds(1)
    #expect(t2.prettyPrinted == "1 s")

    t2 = DispatchTimeInterval.seconds(1_000_0)
    #expect(t2.prettyPrinted == "10000 s")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func prettyPrintMilliseconds() {
    var t2 = DispatchTimeInterval.milliseconds(1)
    #expect(t2.prettyPrinted == "1 ms")

    t2 = .milliseconds(999)
    #expect(t2.prettyPrinted == "999 ms")

    t2 = .milliseconds(1_000)
    #expect(t2.prettyPrinted == "1 s")

    t2 = .milliseconds(1_999)
    #expect(t2.prettyPrinted == "1 s")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func prettyPrintMicroseconds() {
    var t2 = DispatchTimeInterval.microseconds(1)
    #expect(t2.prettyPrinted == "1 µs")

    t2 = .microseconds(999)
    #expect(t2.prettyPrinted == "999 µs")

    t2 = .microseconds(1_000)
    #expect(t2.prettyPrinted == "1 ms")

    t2 = .microseconds(1_999)
    #expect(t2.prettyPrinted == "1 ms")

    t2 = .microseconds(1_000_000)
    #expect(t2.prettyPrinted == "1 s")

    t2 = .microseconds(1_999_999)
    #expect(t2.prettyPrinted == "1 s")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func prettyPrintNanoseconds() {
    var t2 = DispatchTimeInterval.nanoseconds(1)
    #expect(t2.prettyPrinted == "1 ns")

    t2 = .nanoseconds(999)
    #expect(t2.prettyPrinted == "999 ns")

    t2 = .nanoseconds(1_000)
    #expect(t2.prettyPrinted == "1 µs")

    t2 = .nanoseconds(1_999)
    #expect(t2.prettyPrinted == "1 µs")

    t2 = .nanoseconds(1_000_000)
    #expect(t2.prettyPrinted == "1 ms")

    t2 = .nanoseconds(1_999_999)
    #expect(t2.prettyPrinted == "1 ms")

    t2 = .nanoseconds(1_000_000_000)
    #expect(t2.prettyPrinted == "1 s")
  }
}
