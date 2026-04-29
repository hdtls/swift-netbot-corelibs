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

@Suite("V1._ProtocolDNS._MappingTests", .tags(.swiftData, .schema, .dnsMapping))
struct V1_ProtocolDNS_MappingTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let data = V1._ProtocolDNS._Mapping()
    #expect(data.strategy == .mapping)
    #expect(data.isEnabled)
    #expect(data.domainName == "")
    #expect(data.value == "")
    #expect(data.note == "")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("ProtocolDNS.Mapping.init(persistentModel:)")
  func initWithPersistentModel() {
    let persistentModel = V1._ProtocolDNS._Mapping()
    let data = ProtocolDNS.Mapping(persistentModel: persistentModel)

    #expect(data.strategy == persistentModel.strategy)
    #expect(data.domainName == persistentModel.domainName)
    #expect(data.value == persistentModel.value)
    #expect(data.note == persistentModel.note)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func mergeValues() {
    let persistentModel = V1._ProtocolDNS._Mapping()
    let data = ProtocolDNS.Mapping()
    persistentModel.mergeValues(data)

    #expect(data.strategy == persistentModel.strategy)
    #expect(data.domainName == persistentModel.domainName)
    #expect(data.value == persistentModel.value)
    #expect(data.note == persistentModel.note)
  }
}

@Suite("V1._ProtocolDNS._MappingStrategyTests", .tags(.swiftData, .schema, .dnsMapping))
struct V1_ProtocolDNS_Mapping_KindTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: zip(ProtocolDNS.MappingStrategy.allCases, [0, 1, 2]))
  func rawRepresentableConformance(_ strategy: ProtocolDNS.MappingStrategy, _ rawValue: Int) {
    #expect(ProtocolDNS.MappingStrategy(rawValue: rawValue) == strategy)
    #expect(strategy.rawValue == rawValue)
    #expect(ProtocolDNS.MappingStrategy(rawValue: 9) == nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(ProtocolDNS.MappingStrategy.allCases == [.mapping, .cname, .dns])
  }
}
