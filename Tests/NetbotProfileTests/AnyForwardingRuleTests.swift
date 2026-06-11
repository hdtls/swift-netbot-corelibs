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

import Testing

@testable import NetbotProfile

@Suite(.tags(.profile, .forwardingrule))
struct AnyForwardingRuleTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() {
    let data = AnyForwardingRule()
    #expect(data.isEnabled)
    #expect(data.kind == .domain)
    #expect(data.value == "")
    #expect(data.comment == "")
    #expect(data.foreignKey == "DIRECT")
    #expect(data.notification == .init())
  }
}

@Suite(.tags(.profile, .forwardingrule))
struct AnyForwardingRule_KindTests {

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      AnyForwardingRule.Kind.allCases,
      [
        "DOMAIN", "DOMAIN-KEYWORD", "DOMAIN-SUFFIX", "DOMAIN-SET", "RULE-SET", "GEOIP",
        "IP-CIDR", "PROCESS-NAME", "FINAL",
      ]
    ))
  func rawRepresentableConformance(_ kind: AnyForwardingRule.Kind, _ rawValue: String) {
    #expect(AnyForwardingRule.Kind(rawValue: rawValue) == kind)
    #expect(kind.rawValue == rawValue)
    #expect(AnyForwardingRule.Kind(rawValue: "unknown") == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      AnyForwardingRule.Kind.allCases,
      [
        "DOMAIN", "DOMAIN-KEYWORD", "DOMAIN-SUFFIX", "DOMAIN-SET", "RULE-SET", "GEOIP",
        "IP-CIDR", "PROCESS-NAME", "FINAL",
      ]
    ))
  func localizedName(_ kind: AnyForwardingRule.Kind, _ localizedName: String) {
    #expect(kind.localizedName == localizedName)
  }
}

@Suite(.tags(.profile, .forwardingrule))
struct AnyForwardingRule_NotificationTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() {
    let notification = AnyForwardingRule.Notification()
    #expect(notification.message == "")
    #expect(!notification.showNotification)
    #expect(notification.timeInterval == 300)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func equatableConformance() {
    let lhs = AnyForwardingRule.Notification()
    let rhs = AnyForwardingRule.Notification()
    #expect(lhs == rhs)
  }
}
