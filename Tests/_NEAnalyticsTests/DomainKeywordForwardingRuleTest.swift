//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import HTTPTypes
import Testing

@testable import _NEAnalytics

@Suite(.tags(.forwardingRule))
struct DomainKeywordForwardingRuleTest {

  @Test func propertyInitialValue() {
    let data = DomainKeywordForwardingRule(domainKeyword: "test", forwardProtocol: .direct)
    #expect(data.domainKeyword == "test")
    #expect(data.description == "DOMAIN-KEYWORD,test,DIRECT")
  }

  @Test func copyOnWrite() {
    var a = DomainKeywordForwardingRule(domainKeyword: "test", forwardProtocol: .direct)
    let b = a
    let c = a
    a.domainKeyword = "test1"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @Test(
    arguments: zip(
      ["test1.com:443", "sub.test2.com", "test2.com:443", "notmatch.com:443"],
      [true, true, true, false]))
  func predicateWorks(_ authority: String, expected: Bool) {
    let connection = Connection(
      originalRequest: .init(
        httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil)))

    let forwardingRule = DomainKeywordForwardingRule(
      domainKeyword: "test", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let result = try forwardingRule.predicate(connection)
      #expect(result == expected)
    }
  }

  @Test func equatableConformance() async throws {
    let lhs = DomainKeywordForwardingRule(domainKeyword: "test1", forwardProtocol: .direct)
    let rhs = DomainKeywordForwardingRule(domainKeyword: "test2", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = DomainKeywordForwardingRule(domainKeyword: "test1", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = DomainKeywordForwardingRule(domainKeyword: "test1", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
