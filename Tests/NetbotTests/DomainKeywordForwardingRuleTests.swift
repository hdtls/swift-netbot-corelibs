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
struct DomainKeywordForwardingRuleTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() {
    let data = DomainKeywordForwardingRule(domainKeyword: "test", forwardProtocol: .direct)
    #expect(data.domainKeyword == "test")
    #expect(data.description == "DOMAIN-KEYWORD test")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func copyOnWrite() {
    var a = DomainKeywordForwardingRule(domainKeyword: "test", forwardProtocol: .direct)
    let b = a
    let c = a
    a.domainKeyword = "test1"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      ["test1.com:443", "sub.test2.com", "test2.com:443", "notmatch.com:443"],
      [true, true, true, false]))
  func predicateWorks(_ authority: String, expected: Bool) {
    let connection = Connection()
    connection.originalRequest = .init(
      httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil))

    let forwardingRule = DomainKeywordForwardingRule(
      domainKeyword: "test", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let result = try forwardingRule.predicate(connection)
      #expect(result == expected)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func equatableConformance() async throws {
    let lhs = DomainKeywordForwardingRule(domainKeyword: "test1", forwardProtocol: .direct)
    let rhs = DomainKeywordForwardingRule(domainKeyword: "test2", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = DomainKeywordForwardingRule(domainKeyword: "test1", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = DomainKeywordForwardingRule(domainKeyword: "test1", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
