//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import HTTPTypes
import Testing

@testable import _NEAnalytics

@Suite(.tags(.forwardingRule))
struct FinalForwardingRuleTests {

  @Test func propertyInitialValue() {
    let forwardingRule = FinalForwardingRule("test", forwardProtocol: .direct)
    #expect(forwardingRule.condition == "test")
    #expect(forwardingRule.description == "FINAL,test,DIRECT")

    let forwardingRule1 = FinalForwardingRule("", forwardProtocol: .direct)
    #expect(forwardingRule1.condition == "")
    #expect(forwardingRule1.description == "FINAL,DIRECT")
  }

  @Test func copyOnWrite() {
    var a = FinalForwardingRule("test", forwardProtocol: .direct)
    let b = a
    let c = a
    a.condition = ""
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @Test(arguments: ["test1.com:443", "sub.test2.com", "test2.com:443", "notmatch.com:443"])
  func predicateWorks(_ authority: String) {
    let connection = Connection(
      originalRequest: .init(
        httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil)))

    let forwardingRule = FinalForwardingRule("", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let result = try forwardingRule.predicate(connection)
      #expect(result)
    }
  }

  @Test func equatableConformance() async throws {
    let lhs = FinalForwardingRule("test1", forwardProtocol: .direct)
    let rhs = FinalForwardingRule("test2", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = FinalForwardingRule("test1", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = FinalForwardingRule("test1", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
