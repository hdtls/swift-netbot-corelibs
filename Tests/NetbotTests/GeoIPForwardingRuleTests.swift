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

import NetbotLite
import Testing

@testable import Netbot

@Suite(.tags(.forwardingrule))
struct GeoIPForwardingRuleTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() {
    let forwardingRule = GeoIPForwardingRule(
      db: nil, countryCode: "CN", forwardProtocol: .direct)
    #expect(forwardingRule.countryCode == "CN")
    #expect(forwardingRule.description == "GEOIP CN")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func copyOnWrite() {
    var a = GeoIPForwardingRule(db: nil, countryCode: "CN", forwardProtocol: .direct)
    let b = a
    let c = a
    a.countryCode = "US"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func equatableConformance() async throws {
    let lhs = GeoIPForwardingRule(db: nil, countryCode: "CN", forwardProtocol: .direct)
    let rhs = GeoIPForwardingRule(db: nil, countryCode: "US", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = GeoIPForwardingRule(db: nil, countryCode: "CN", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = GeoIPForwardingRule(db: nil, countryCode: "CN", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
