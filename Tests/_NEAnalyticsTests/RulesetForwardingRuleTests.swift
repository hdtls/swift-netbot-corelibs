//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Testing

@testable import _NEAnalytics

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.forwardingRule))
struct RulesetForwardingRuleTests {

  private let externalResourceDirectory: URL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().appending(path: "External Resource")

  @Test func propertyInitialValue() async throws {
    let data = RulesetForwardingRule(
      originalURLString: #filePath, forwardProtocol: .direct)
    #expect(data.originalURLString == #filePath)
    #expect(data.externalRules.isEmpty)
    #expect(data.description == "RULE-SET,\(#filePath),DIRECT")
  }

  @Test func externalResourceDoesNotExists() async throws {
    let data = RulesetForwardingRule(
      originalURLString: #filePath, forwardProtocol: .direct)
    #expect(data.originalURLString == #filePath)
    #expect(data.externalRules.isEmpty)
    #expect(data.description == "RULE-SET,\(#filePath),DIRECT")
  }

  @Test func externalRulesProcessing() async throws {
    let forwardingRule = RulesetForwardingRule(
      externalResourceDirectory: externalResourceDirectory,
      originalURLString: "https://example.com/forwarding_rules", forwardProtocol: .direct)
    #expect(forwardingRule.originalURLString == "https://example.com/forwarding_rules")
    #expect(!forwardingRule.externalRules.isEmpty)
    #expect(forwardingRule.externalRules.count == 5)
    #expect(forwardingRule.description == "RULE-SET,https://example.com/forwarding_rules,DIRECT")
  }

  @Test func setOriginalURLString() async throws {
    var forwardingRule = RulesetForwardingRule(
      externalResourceDirectory: externalResourceDirectory, originalURLString: #filePath,
      forwardProtocol: .direct)
    #expect(forwardingRule.originalURLString == #filePath)
    #expect(forwardingRule.externalRules.isEmpty)
    #expect(forwardingRule.description == "RULE-SET,\(#filePath),DIRECT")

    forwardingRule.originalURLString = "https://example.com/forwarding_rules"
    #expect(forwardingRule.originalURLString == "https://example.com/forwarding_rules")
    #expect(!forwardingRule.externalRules.isEmpty)
    #expect(forwardingRule.externalRules.count == 5)
    #expect(forwardingRule.description == "RULE-SET,https://example.com/forwarding_rules,DIRECT")
  }

  @Test func copyOnWrite() async throws {
    var a = RulesetForwardingRule(
      externalResourceDirectory: externalResourceDirectory, originalURLString: #filePath,
      forwardProtocol: .direct)
    let b = a
    let c = a
    a.originalURLString = "https://example.com/forwarding_rules"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @Test(arguments: [
    "www.test.com", "test1.com:443", "sub.test2.com", "test2.com:443", "test2.a.com",
  ])
  func predicateWorks(_ authority: String) async throws {
    let connection = Connection(
      originalRequest: .init(
        httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil)))

    let forwardingRule = RulesetForwardingRule(
      externalResourceDirectory: externalResourceDirectory,
      originalURLString: "https://example.com/forwarding_rules", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let result = try forwardingRule.predicate(connection)
      #expect(result)
    }
  }

  @Test func equatableConformance() async throws {
    let lhs = RulesetForwardingRule(
      originalURLString: "https://test1.com/forwarding_rules", forwardProtocol: .direct)
    let rhs = RulesetForwardingRule(
      originalURLString: "https://test2.com/forwarding_rules", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = RulesetForwardingRule(
      originalURLString: "https://test1.com/forwarding_rules", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = RulesetForwardingRule(
      originalURLString: "https://test1.com/forwarding_rules", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
