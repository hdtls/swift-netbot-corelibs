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

import HTTPTypes
import NetbotLite
import NetbotLiteData
import Testing

@testable import Netbot

@Suite(.tags(.forwardingrule))
struct DomainForwardingRuleTest {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() {
    let data = DomainForwardingRule(domain: "example.com", forwardProtocol: .direct)
    #expect(data.domain == "example.com")
    #expect(data.description == "DOMAIN example.com")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func copyOnWrite() {
    var a = DomainForwardingRule(domain: "example.com", forwardProtocol: .direct)
    let b = a
    let c = a
    a.domain = "example1.com"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: zip(["test1.com:443", "sub.test2.com", "test2.com:443"], [false, false, true]))
  func predicateWorks(_ authority: String, expected: Bool) {
    let connection = Connection()
    connection.originalRequest = .init(
      httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil))

    let forwardingRule = DomainForwardingRule(domain: "test2.com", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let result = try forwardingRule.predicate(connection)
      #expect(result == expected)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func equatableConformance() async throws {
    let lhs = DomainForwardingRule(domain: "test1.com", forwardProtocol: .direct)
    let rhs = DomainForwardingRule(domain: "test2.com", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = DomainForwardingRule(domain: "test1.com", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = DomainForwardingRule(domain: "test1.com", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
