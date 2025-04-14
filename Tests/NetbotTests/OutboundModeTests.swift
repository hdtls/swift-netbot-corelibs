//
// See LICENSE.txt for license information
//

import Preference
import Testing

@testable import Netbot

@Suite struct OutboundModeTests {

  @Test(
    arguments: zip(
      OutboundMode.allCases,
      [
        "All requests will be sent directly", "All requests will be forwarded to a proxy server",
        "All requests will be forwarded base on rule system",
      ]))
  func localizedDescription(_ mode: OutboundMode, _ description: String) {
    #expect(mode.localizedDescription == description)
  }

  @Test(arguments: zip(OutboundMode.allCases, ["direct-outbound", "global-proxy", "rule-based"]))
  func rawRepresentableConformance(_ mode: OutboundMode, _ rawValue: String) {
    #expect(mode.rawValue == rawValue)
    #expect(OutboundMode(rawValue: rawValue) == mode)
    #expect(OutboundMode(rawValue: "unknown") == nil)
  }

  @Test func caseIterableConformance() {
    #expect(OutboundMode.allCases == [.direct, .globalProxy, .ruleBased])
  }

  @Test(arguments: zip(OutboundMode.allCases, ["direct-outbound", "global-proxy", "rule-based"]))
  func preferenceRepresentableConformance(_ mode: OutboundMode, _ preferenceValue: String) {
    #expect(mode.preferenceValue as? String == preferenceValue)
    #expect(OutboundMode(preferenceValue: preferenceValue) == mode)
  }
}
