//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import Testing

@testable import _ProfileSupport

@Suite("V1._DNSMappingTests", .tags(.swiftData, .schema, .dnsMapping))
struct DNSMappingPersistentModelTests {

  @available(SwiftStdlib 5.9, *)
  @Test func propertyInitialValue() {
    let data = V1._DNSMapping()
    #expect(data.kind == .mapping)
    #expect(data.isEnabled)
    #expect(data.domainName == "")
    #expect(data.value == "")
    #expect(data.note == "")
  }

  @available(SwiftStdlib 5.9, *)
  @Test("DNSMapping.init(persistentModel:)")
  func initWithPersistentModel() {
    let persistentModel = V1._DNSMapping()
    let data = DNSMapping(persistentModel: persistentModel)

    #expect(data.kind == persistentModel.kind)
    #expect(data.domainName == persistentModel.domainName)
    #expect(data.value == persistentModel.value)
    #expect(data.note == persistentModel.note)
  }

  @available(SwiftStdlib 5.9, *)
  @Test func mergeValues() {
    let persistentModel = V1._DNSMapping()
    let data = DNSMapping()
    persistentModel.mergeValues(data)

    #expect(data.kind == persistentModel.kind)
    #expect(data.domainName == persistentModel.domainName)
    #expect(data.value == persistentModel.value)
    #expect(data.note == persistentModel.note)
  }
}

@Suite("V1._DNSMapping.KindTests", .tags(.swiftData, .schema, .dnsMapping))
struct V1_DNSMappingKindTests {

  @available(SwiftStdlib 5.9, *)
  @Test(arguments: zip(V1._DNSMapping.Kind.allCases, [0, 1, 2]))
  func rawRepresentableConformance(_ kind: V1._DNSMapping.Kind, _ rawValue: Int) {
    #expect(V1._DNSMapping.Kind(rawValue: rawValue) == kind)
    #expect(kind.rawValue == rawValue)
    #expect(V1._DNSMapping.Kind(rawValue: 9) == nil)
  }

  @available(SwiftStdlib 5.9, *)
  @Test func caseIterableConformance() {
    #expect(V1._DNSMapping.Kind.allCases == [.mapping, .cname, .dns])
  }
}
