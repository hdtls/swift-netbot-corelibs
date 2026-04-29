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

import NEAddressProcessing
import NIOCore
import NetbotLite
import NetbotLiteData
import Testing

@testable import Netbot

@Suite(.tags(.forwardingRule))
struct IPCIDRForwardingRuleTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() async throws {
    let forwardingRule = FINALForwardingRule("test", forwardProtocol: .direct)
    #expect(forwardingRule.condition == "test")
    #expect(forwardingRule.description == "FINAL")

    let forwardingRule1 = FINALForwardingRule("", forwardProtocol: .direct)
    #expect(forwardingRule1.condition == "")
    #expect(forwardingRule1.description == "FINAL")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func copyOnWrite() async throws {
    var a = FINALForwardingRule("test", forwardProtocol: .direct)
    let b = a
    let c = a
    a.condition = ""
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      [
        "192.168.0.9", "192.168.16.1", "2001:4860:4860::8888",
        "2001:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF",
      ], [true, false, false, false]))
  func matchIPWithIPv4IPCIDRRule(_ pattern: String, expected: Bool) {
    let forwardingRule = IPCIDRForwardingRule(
      uncheckedBounds: "192.168.0.1/20", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let connection = Connection()
      connection.originalRequest = .init(address: .hostPort(host: .init(pattern), port: 0))
      let result = try forwardingRule.predicate(connection)
      #expect(result == expected)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      [
        "192.168.0.9", "192.168.16.1", "2001:4860:4860::8888",
        "2001:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF",
      ], [false, false, true, false]))
  func matchIPWithIPv6IPCIDRRule(_ pattern: String, expected: Bool) {
    let forwardingRule = IPCIDRForwardingRule(
      uncheckedBounds: "2001:4860:4860::8888/32", forwardProtocol: .direct)

    #expect(throws: Never.self) {
      let connection = Connection()
      connection.originalRequest = .init(address: .hostPort(host: .init(pattern), port: 0))
      let result = try forwardingRule.predicate(connection)
      #expect(result == expected)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func equatableConformance() async throws {
    let lhs = IPCIDRForwardingRule(uncheckedBounds: "192.168.0.1/20", forwardProtocol: .direct)
    let rhs = IPCIDRForwardingRule(
      uncheckedBounds: "2001:4860:4860::8888/32", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = IPCIDRForwardingRule(uncheckedBounds: "192.168.0.1/20", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = IPCIDRForwardingRule(uncheckedBounds: "192.168.0.1/20", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
