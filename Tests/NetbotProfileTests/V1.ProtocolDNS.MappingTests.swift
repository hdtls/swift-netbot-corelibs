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

@Suite(.tags(.profile, .dns, .swiftdata))
struct V1_ProtocolDNS_MappingTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
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

@Suite(.tags(.profile, .dns, .swiftdata))
struct V1_ProtocolDNS_Mapping_KindTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(ProtocolDNS.MappingStrategy.allCases == [.mapping, .cname, .dns])
  }
}
