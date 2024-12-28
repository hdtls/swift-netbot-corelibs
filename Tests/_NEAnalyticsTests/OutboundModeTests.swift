//
// See LICENSE.txt for license information
//

import Anlzr
import Testing

@testable import _NEAnalytics

@Suite struct OutboundModeTests {
  @Test(
    arguments: zip(
      [OutboundMode.direct, .globalProxy, .ruleBased],
      ["Direct Outbound", "Global Proxy", "Rule-based Proxy"]))
  func localizedName(_ mode: OutboundMode, _ localizedName: String) {
    #expect(mode.localizedName == localizedName)
  }
}
