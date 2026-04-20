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

import NetbotLite
import Testing

@testable import Netbot

@Suite(.tags(.forwardingRule))
struct GeoIPForwardingRuleTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let forwardingRule = GeoIPForwardingRule(
      db: nil, countryCode: "CN", forwardProtocol: .direct)
    #expect(forwardingRule.countryCode == "CN")
    #expect(forwardingRule.description == "GEOIP CN")
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func copyOnWrite() {
    var a = GeoIPForwardingRule(db: nil, countryCode: "CN", forwardProtocol: .direct)
    let b = a
    let c = a
    a.countryCode = "US"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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
