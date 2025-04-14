//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import HTTPTypes
import Testing

@testable import _NEAnalytics

@Suite(.tags(.forwardingRule))
struct DomainForwardingRuleTest {

  @Test func propertyInitialValue() {
    let data = DomainForwardingRule(domain: "example.com", forwardProtocol: .direct)
    #expect(data.domain == "example.com")
    #expect(data.description == "DOMAIN,example.com,DIRECT")
  }

  @Test func copyOnWrite() {
    var a = DomainForwardingRule(domain: "example.com", forwardProtocol: .direct)
    let b = a
    let c = a
    a.domain = "example1.com"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @Test(arguments: zip(["test1.com:443", "sub.test2.com", "test2.com:443"], [false, false, true]))
  func predicateWorks(_ authority: String, expected: Bool) {
    let connection = Connection(
      originalRequest: .init(
        httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil)))

    let forwardingRule = DomainForwardingRule(domain: "test2.com", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let result = try forwardingRule.predicate(connection)
      #expect(result == expected)
    }
  }

  @Test func equatableConformance() async throws {
    let lhs = DomainForwardingRule(domain: "test1.com", forwardProtocol: .direct)
    let rhs = DomainForwardingRule(domain: "test2.com", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = DomainForwardingRule(domain: "test1.com", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = DomainForwardingRule(domain: "test1.com", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
