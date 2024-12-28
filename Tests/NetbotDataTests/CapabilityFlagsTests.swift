//
// See LICENSE.txt for license information
//

import Testing

@testable import NetbotData

@Suite struct CapabilityFlagsTests {

  @Test(
    arguments: zip(
      CapabilityFlags.allCases,
      ["Enable HTTP Capture", "Enable HTTPS MitM", "Enable Rewrite", "Enable Scripting"]
    )
  )
  func localizedName(_ capability: CapabilityFlags, _ localizedName: String) {
    #expect(capability.localizedName == localizedName)
  }

  @Test func caseIterableConformance() {
    #expect(CapabilityFlags.allCases == [.httpCapture, .httpsDecryption, .rewrite, .scripting])
  }
}
