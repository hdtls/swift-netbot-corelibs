//
// See LICENSE.txt for license information
//

import Testing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct DateRawRepresentableTests {

  @Test func create() {
    let expected = Date()
    #expect(Date(rawValue: expected.rawValue) == expected)
  }

  @Test func createWithInvalidRawValue() {
    #expect(Date(rawValue: "") == nil)
  }

  @Test func rawValue() {
    let date = Date()
    #expect(date.rawValue == date.timeIntervalSinceReferenceDate.description)
  }
}
