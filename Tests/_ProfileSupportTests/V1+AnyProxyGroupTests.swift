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

@Suite("V1._AnyProxyGroupTests", .tags(.swiftData, .schema, .proxyGroup))
struct V1_AnyProxyGroupTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let persistentModel = V1._AnyProxyGroup()
    #expect(persistentModel.kind == .select)
    #expect(persistentModel.resource == .init())
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("AnyProxyGroup.init(persistentModel:)")
  func initWithPersistentModel() {
    let persistentModel = V1._AnyProxyGroup()
    let group = AnyProxyGroup(persistentModel: persistentModel)

    #expect(group.name == persistentModel.name)
    #expect(group.kind == persistentModel.kind)
    #expect(group.resource == persistentModel.resource)
    #expect(group.measurement == persistentModel.measurement)
    #expect(group.creationDate == persistentModel.creationDate)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func mergeValues() {
    let persistentModel = V1._AnyProxyGroup()
    let group = AnyProxyGroup()
    persistentModel.mergeValues(group)

    #expect(persistentModel.name == group.name)
    #expect(persistentModel.kind == group.kind)
    #expect(persistentModel.resource == group.resource)
    #expect(persistentModel.measurement == group.measurement)
    #expect(persistentModel.creationDate == group.creationDate)
  }
}

@Suite("V1._AnyProxyGroup.KindTests", .tags(.swiftData, .schema, .proxyGroup))
struct V1_AnyProxyGroupKindTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      V1._AnyProxyGroup.Kind.allCases,
      [
        "Select Group", "Auto URL Test Group", "Fallback Group", "SSID Group",
        "Load Balance Group",
      ]
    )
  )
  func localizedName(_ kind: V1._AnyProxyGroup.Kind, _ localizedName: String) {
    #expect(kind.localizedName == localizedName)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      V1._AnyProxyGroup.Kind.allCases,
      [
        "Select which policy will be used on user interface.",
        "Automatically select which policy will be used by benchmarking the latency to a URL.",
        "Automatically select an available policy by priority. The availability is tested by accessing a URL like the auto URL test group.",
        "Select which policy will be used according to the current Wi-Fi SSID.",
        "Use a random sub-policy for every connections.",
      ]
    )
  )
  func localizedDescription(_ kind: V1._AnyProxyGroup.Kind, _ description: String) {
    #expect(kind.localizedDescription == description)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(
      V1._AnyProxyGroup.Kind.allCases == [.select, .urlTest, .fallback, .ssid, .loadBalance])
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      V1._AnyProxyGroup.Kind.allCases,
      ["select", "url-test", "fallback", "ssid", "load-balance"]
    )
  )
  func rawRepresentableConformance(_ kind: V1._AnyProxyGroup.Kind, _ rawValue: String) {
    #expect(kind.rawValue == rawValue)
    #expect(V1._AnyProxyGroup.Kind(rawValue: rawValue) == kind)
    #expect(V1._AnyProxyGroup.Kind(rawValue: "unknown") == nil)
  }
}

@Suite("V1_AnyProxyGroup.MeasurementTests", .tags(.swiftData, .schema, .proxyGroup))
struct V1_AnyProxyGroupMeasurementTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let transactionMetrics = TransactionMetrics()
    let measurement = V1._AnyProxyGroup.Measurement(transactionMetrics: transactionMetrics)
    #expect(measurement.url == nil)
    #expect(measurement.transactionMetricsExpiryInterval == 600.0)
    #expect(measurement.timeout == 5.0)
    #expect(measurement.tolerance == 100)
    #expect(measurement.transactionMetrics == transactionMetrics)
  }
}

@Suite("V1._AnyProxyGroup.ResourceTests", .tags(.swiftData, .schema, .proxyGroup))
struct V1_AnyProxyGroupResourceTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let resource = V1._AnyProxyGroup.Resource()
    #expect(resource.source == .cache)
    #expect(resource.externalProxiesURL == nil)
    #expect(resource.externalProxiesAutoUpdateTimeInterval == 86400)
  }
}

@Suite("V1._AnyProxyGroup.Resource.SourceTests", .tags(.swiftData, .schema, .proxyGroup))
struct V1_AnyProxyGroupResourceSourceTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(V1._AnyProxyGroup.Resource.Source.allCases == [.cache, .query])
  }
}
