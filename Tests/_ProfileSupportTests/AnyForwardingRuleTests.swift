//
// See LICENSE.txt for license information
//

import Testing

@testable import _ProfileSupport

@Suite(.tags(.forwardingRule))
struct AnyForwardingRuleTests {

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
  @Test func propertyInitialValue() {
    let notification = AnyForwardingRule.Notification()
    #expect(notification.message == "")
    #expect(!notification.showNotification)
    #expect(notification.timeInterval == 300)
  }

  @Test func equatableConformance() {
    let lhs = AnyForwardingRule.Notification()
    let rhs = AnyForwardingRule.Notification()
    #expect(lhs == rhs)
  }
}
