// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import Testing

@testable import NetbotProfile

@Suite(.tags(.profile, .dns))
struct ProtocolDNS_MappingTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() {
    let data = ProtocolDNS.Mapping()
    #expect(data.strategy == .mapping)
    #expect(data.isEnabled)
    #expect(data.domainName == "")
    #expect(data.value == "")
    #expect(data.note == "")
  }
}

@Suite(.tags(.profile, .dns))
struct ProtocolDNS_MappingStrategyTests {

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: zip(ProtocolDNS.MappingStrategy.allCases, [0, 1, 2]))
  func rawRepresentableConformance(_ kind: ProtocolDNS.MappingStrategy, _ rawValue: Int) {
    #expect(ProtocolDNS.MappingStrategy(rawValue: rawValue) == kind)
    #expect(kind.rawValue == rawValue)
    #expect(ProtocolDNS.MappingStrategy(rawValue: 9) == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func caseIterableConformance() {
    #expect(ProtocolDNS.MappingStrategy.allCases == [.mapping, .cname, .dns])
  }
}
