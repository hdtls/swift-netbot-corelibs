//
// See LICENSE.txt for license information
//

import Testing

@testable import _ProfileSupport

@Suite(.tags(.dnsMapping))
struct DNSMappingTests {

  @Test func propertyInitialValue() {
    let data = DNSMapping()
    #expect(data.kind == .mapping)
    #expect(data.isEnabled)
    #expect(data.domainName == "")
    #expect(data.value == "")
    #expect(data.note == "")
  }
}

@Suite("DNSMapping.KindTests", .tags(.dnsMapping))
struct DNSMappingKindTests {

  @Test(arguments: zip(DNSMapping.Kind.allCases, [0, 1, 2]))
  func rawRepresentableConformance(_ kind: DNSMapping.Kind, _ rawValue: Int) {
    #expect(DNSMapping.Kind(rawValue: rawValue) == kind)
    #expect(kind.rawValue == rawValue)
    #expect(DNSMapping.Kind(rawValue: 9) == nil)
  }

  @Test func caseIterableConformance() {
    #expect(DNSMapping.Kind.allCases == [.mapping, .cname, .dns])
  }
}
