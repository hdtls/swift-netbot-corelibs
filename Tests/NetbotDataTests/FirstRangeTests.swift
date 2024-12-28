//
// See LICENSE.txt for license information
//

import Testing

@testable import NetbotData

@Suite struct FirstRangeTests {

  @Test(
    arguments: [
      (["[A]"], 1...1),
      (["", "[A]"], 2...2),
      (["", "[A]", "[B]"], 2...2),
      (["", "[A]", ""], 2...2),
      (["", "[A]", "", ""], 2...2),
      (["", "[A]", "", "[B]"], 2...2),
      (["", "[A]", "", "", "", "[B]"], 2...2),
      (["", "[A]", "", "A", "", "[B]"], 2...4),
      (["", "[A]", "", "A", "", "", "[B]"], 2...4),
    ]
  )
  func firstRange(_ source: [Substring], expected: ClosedRange<Int>) {
    #expect([].firstRange(match: /\[A]/) == nil)
    #expect([""].firstRange(match: /\[A]/) == nil)
    #expect(source.firstRange(match: /\[A]/) == expected)
  }
}
