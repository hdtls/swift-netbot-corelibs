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

@Suite(.tags(.forwardingRule))
struct AnyForwardingRuleTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

@Suite("AnyForwardingRule.KindTests", .tags(.forwardingRule))
struct AnyForwardingRuleKindTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

@Suite("AnyForwardingRule.NotificationTests", .tags(.forwardingRule))
struct AnyForwardingRuleNotificationTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let notification = AnyForwardingRule.Notification()
    #expect(notification.message == "")
    #expect(!notification.showNotification)
    #expect(notification.timeInterval == 300)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func equatableConformance() {
    let lhs = AnyForwardingRule.Notification()
    let rhs = AnyForwardingRule.Notification()
    #expect(lhs == rhs)
  }
}
