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

@Suite(.tags(.profile, .forwardingrule, .swiftdata))
struct V1_AnyForwardingRuleTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() {
    let data = V1._AnyForwardingRule()
    #expect(data.isEnabled)
    #expect(data.kind == .domain)
    #expect(data.value == "")
    #expect(data.comment == "")
    //      #expect(data.foreignKey == "direct")
    #expect(data.notification == .init())
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mergeValues() {
    let persistentModel = V1._AnyForwardingRule()
    let forwardingRule = AnyForwardingRule()
    persistentModel.mergeValues(forwardingRule)

    #expect(persistentModel.isEnabled == forwardingRule.isEnabled)
    #expect(persistentModel.kind == forwardingRule.kind)
    #expect(persistentModel.value == forwardingRule.value)
    #expect(persistentModel.comment == forwardingRule.comment)
    #expect(persistentModel.notification == forwardingRule.notification)
  }
}

@Suite(.tags(.profile, .forwardingrule, .swiftdata))
struct V1_AnyForwardingRule_KindTests {

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      V1._AnyForwardingRule.Kind.allCases,
      [
        "DOMAIN", "DOMAIN-KEYWORD", "DOMAIN-SUFFIX", "DOMAIN-SET", "RULE-SET", "GEOIP",
        "IP-CIDR", "PROCESS-NAME", "FINAL",
      ]
    ))
  func rawRepresentableConformance(_ kind: V1._AnyForwardingRule.Kind, _ rawValue: String) {
    #expect(V1._AnyForwardingRule.Kind(rawValue: rawValue) == kind)
    #expect(kind.rawValue == rawValue)
    #expect(V1._AnyForwardingRule.Kind(rawValue: "unknown") == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      V1._AnyForwardingRule.Kind.allCases,
      [
        "DOMAIN", "DOMAIN-KEYWORD", "DOMAIN-SUFFIX", "DOMAIN-SET", "RULE-SET", "GEOIP",
        "IP-CIDR", "PROCESS-NAME", "FINAL",
      ]
    ))
  func localizedName(_ kind: V1._AnyForwardingRule.Kind, _ localizedName: String) {
    #expect(kind.localizedName == localizedName)
  }
}

@Suite(.tags(.profile, .forwardingrule, .swiftdata))
struct V1_AnyForwardingRule_NotificationTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() {
    let notification = V1._AnyForwardingRule.Notification()
    #expect(notification.message == "")
    #expect(!notification.showNotification)
    #expect(notification.timeInterval == 300)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func equatableConformance() async throws {
    let lhs = V1._AnyForwardingRule.Notification()
    let rhs = V1._AnyForwardingRule.Notification()
    #expect(lhs == rhs)
  }
}
