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

import HTTPTypes
import NetbotLite
import NetbotLiteData
import Testing

@testable import Netbot

@Suite(.tags(.forwardingRule))
struct FinalForwardingRuleTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
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
  @Test func copyOnWrite() {
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
  @Test(arguments: ["test1.com:443", "sub.test2.com", "test2.com:443", "notmatch.com:443"])
  func predicateWorks(_ authority: String) {
    let connection = Connection()
    connection.originalRequest = .init(
      httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil))

    let forwardingRule = FINALForwardingRule("", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let result = try forwardingRule.predicate(connection)
      #expect(result)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func equatableConformance() async throws {
    let lhs = FINALForwardingRule("test1", forwardProtocol: .direct)
    let rhs = FINALForwardingRule("test2", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = FINALForwardingRule("test1", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = FINALForwardingRule("test1", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
