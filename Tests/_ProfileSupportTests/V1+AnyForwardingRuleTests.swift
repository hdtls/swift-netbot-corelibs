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

import Testing

@testable import _ProfileSupport

@Suite("V1._AnyForwardingRuleTests", .tags(.swiftData, .schema, .forwardingRule))
struct AnyRulePersistentModelTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let data = V1._AnyForwardingRule()
    #expect(data.isEnabled)
    #expect(data.kind == .domain)
    #expect(data.value == "")
    #expect(data.comment == "")
    //      #expect(data.foreignKey == "direct")
    #expect(data.notification == .init())
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

@Suite("V1._AnyForwardingRule.KindTests", .tags(.swiftData, .schema, .forwardingRule))
struct V1_AnyRuleKindTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

@Suite("V1._AnyForwardingRule.NotificationTests", .tags(.swiftData, .schema, .forwardingRule))
struct V1_AnyRuleNotificationTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let notification = V1._AnyForwardingRule.Notification()
    #expect(notification.message == "")
    #expect(!notification.showNotification)
    #expect(notification.timeInterval == 300)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func equatableConformance() async throws {
    let lhs = V1._AnyForwardingRule.Notification()
    let rhs = V1._AnyForwardingRule.Notification()
    #expect(lhs == rhs)
  }
}
