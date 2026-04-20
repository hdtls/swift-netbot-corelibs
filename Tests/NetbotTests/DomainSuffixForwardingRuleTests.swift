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
struct DomainSuffixForwardingRuleTests {

  @Test func propertyInitialValue() {
    let data = DomainSuffixForwardingRule(domainSuffix: "test.com", forwardProtocol: .direct)
    #expect(data.domainSuffix == "test.com")
    #expect(data.description == "DOMAIN-SUFFIX test.com")
  }

  @Test func copyOnWrite() {
    var a = DomainSuffixForwardingRule(domainSuffix: "test.com", forwardProtocol: .direct)
    let b = a
    let c = a
    a.domainSuffix = "test1.com"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @Test(
    arguments: zip(
      ["test1.com:443", "sub.test2.com", "test2.com:443", "test.com:443"],
      [false, false, false, true]))
  func predicateWorks(_ authority: String, expected: Bool) {
    let connection = Connection()
    connection.originalRequest = .init(
      httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil))

    let forwardingRule = DomainSuffixForwardingRule(
      domainSuffix: "test.com", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let result = try forwardingRule.predicate(connection)
      #expect(result == expected)
    }
  }

  @Test func equatableConformance() async throws {
    let lhs = DomainSuffixForwardingRule(domainSuffix: "test1.com", forwardProtocol: .direct)
    let rhs = DomainSuffixForwardingRule(domainSuffix: "test2.com", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = DomainSuffixForwardingRule(
      domainSuffix: "test1.com", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = DomainSuffixForwardingRule(
      domainSuffix: "test1.com", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
