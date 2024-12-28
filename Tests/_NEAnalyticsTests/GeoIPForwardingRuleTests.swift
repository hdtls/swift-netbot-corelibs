//
// See LICENSE.txt for license information
//

import Anlzr
import Testing

@testable import _NEAnalytics

@Suite(.tags(.forwardingRule))
struct GeoIPForwardingRuleTests {

  @Test func propertyInitialValue() {
    let forwardingRule = GeoIPForwardingRule(
      db: nil, countryCode: "CN", forwardProtocol: .direct)
    #expect(forwardingRule.countryCode == "CN")
    #expect(forwardingRule.description == "GEOIP,CN,DIRECT")
  }

  @Test func copyOnWrite() {
    var a = GeoIPForwardingRule(db: nil, countryCode: "CN", forwardProtocol: .direct)
    let b = a
    let c = a
    a.countryCode = "US"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @Test func equatableConformance() async throws {
    let lhs = GeoIPForwardingRule(db: nil, countryCode: "CN", forwardProtocol: .direct)
    let rhs = GeoIPForwardingRule(db: nil, countryCode: "US", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = GeoIPForwardingRule(db: nil, countryCode: "CN", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = GeoIPForwardingRule(db: nil, countryCode: "CN", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
