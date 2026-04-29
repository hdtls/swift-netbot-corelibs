// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Testing

@testable import _ProfileSupport

@Suite(.tags(.dnsMapping))
struct ProtocolDNS_MappingTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let data = ProtocolDNS.Mapping()
    #expect(data.strategy == .mapping)
    #expect(data.isEnabled)
    #expect(data.domainName == "")
    #expect(data.value == "")
    #expect(data.note == "")
  }
}

@Suite("ProtocolDNS.MappingStrategyTests", .tags(.dnsMapping))
struct ProtocolDNS_Mapping_KindTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: zip(ProtocolDNS.MappingStrategy.allCases, [0, 1, 2]))
  func rawRepresentableConformance(_ kind: ProtocolDNS.MappingStrategy, _ rawValue: Int) {
    #expect(ProtocolDNS.MappingStrategy(rawValue: rawValue) == kind)
    #expect(kind.rawValue == rawValue)
    #expect(ProtocolDNS.MappingStrategy(rawValue: 9) == nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(ProtocolDNS.MappingStrategy.allCases == [.mapping, .cname, .dns])
  }
}
