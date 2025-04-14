//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import HTTPTypes
import Testing

@testable import _NEAnalytics

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.forwardingRule))
struct DomainsetForwardingRuleTests {

  private let externalResourceDirectory: URL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().appending(path: "External Resource")

  @Test func propertyInitialValue() {
    let data = DomainsetForwardingRule(
      originalURLString: #filePath, forwardProtocol: .direct)
    #expect(data.originalURLString == #filePath)
    #expect(data.externalDomains.isEmpty)
    #expect(data.description == "DOMAIN-SET,\(#filePath),DIRECT")
  }

  @Test func externalResourceDoesNotExists() async throws {
    let data = DomainsetForwardingRule(
      originalURLString: #filePath, forwardProtocol: .direct)
    #expect(data.originalURLString == #filePath)
    #expect(data.externalDomains.isEmpty)
    #expect(data.description == "DOMAIN-SET,\(#filePath),DIRECT")
  }

  @Test func externalDomainsProcessing() async throws {
    let forwardingRule = DomainsetForwardingRule(
      externalResourceDirectory: externalResourceDirectory,
      originalURLString: "https://example.com/domains", forwardProtocol: .direct)
    #expect(forwardingRule.originalURLString == "https://example.com/domains")
    #expect(!forwardingRule.externalDomains.isEmpty)
    #expect(forwardingRule.externalDomains == ["test1.com", ".test2.com"])
    #expect(forwardingRule.description == "DOMAIN-SET,https://example.com/domains,DIRECT")
  }

  @Test func setOriginalURLString() async throws {
    var forwardingRule = DomainsetForwardingRule(
      externalResourceDirectory: externalResourceDirectory, originalURLString: #filePath,
      forwardProtocol: .direct)
    #expect(forwardingRule.originalURLString == #filePath)
    #expect(forwardingRule.externalDomains.isEmpty)
    #expect(forwardingRule.description == "DOMAIN-SET,\(#filePath),DIRECT")

    forwardingRule.originalURLString = "https://example.com/domains"
    #expect(forwardingRule.originalURLString == "https://example.com/domains")
    #expect(!forwardingRule.externalDomains.isEmpty)
    #expect(forwardingRule.externalDomains == ["test1.com", ".test2.com"])
    #expect(forwardingRule.description == "DOMAIN-SET,https://example.com/domains,DIRECT")
  }

  @Test func copyOnWrite() {
    var a = DomainsetForwardingRule(
      externalResourceDirectory: externalResourceDirectory, originalURLString: #filePath,
      forwardProtocol: .direct)
    let b = a
    let c = a
    a.originalURLString = "https://example.com/domains"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @Test(arguments: ["test1.com:443", "sub.test2.com", "test2.com:443"])
  func predicateWorks(_ authority: String) {
    let connection = Connection(
      originalRequest: .init(
        httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil)))

    let forwardingRule = DomainsetForwardingRule(
      externalResourceDirectory: externalResourceDirectory,
      originalURLString: "https://example.com/domains", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      _ = try forwardingRule.predicate(connection)
    }
  }

  @Test func equatableConformance() {
    let lhs = DomainsetForwardingRule(
      originalURLString: "https://test1.com/domains", forwardProtocol: .direct)
    let rhs = DomainsetForwardingRule(
      originalURLString: "https://test2.com/domains", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = DomainsetForwardingRule(
      originalURLString: "https://test1.com/domains", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = DomainsetForwardingRule(
      originalURLString: "https://test1.com/domains", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
