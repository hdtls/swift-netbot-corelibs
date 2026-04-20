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

@Suite(.tags(.proxyGroup)) struct AnyProxyGroupTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() async throws {
    let persistentModel = AnyProxyGroup()
    #expect(persistentModel.kind == .select)
    #expect(persistentModel.resource == .init())
  }
}

@Suite("AnyProxyGroup.KindTests", .tags(.proxyGroup))
struct AnyProxyGroupKindTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      AnyProxyGroup.Kind.allCases,
      [
        "Select Group", "Auto URL Test Group", "Fallback Group", "SSID Group",
        "Load Balance Group",
      ]
    )
  )
  func localizedName(_ kind: AnyProxyGroup.Kind, _ localizedName: String) {
    #expect(kind.localizedName == localizedName)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      AnyProxyGroup.Kind.allCases,
      [
        "Select which policy will be used on user interface.",
        "Automatically select which policy will be used by benchmarking the latency to a URL.",
        "Automatically select an available policy by priority. The availability is tested by accessing a URL like the auto URL test group.",
        "Select which policy will be used according to the current Wi-Fi SSID.",
        "Use a random sub-policy for every connections.",
      ]
    )
  ) func localizedDescription(_ kind: AnyProxyGroup.Kind, _ description: String) {
    #expect(kind.localizedDescription == description)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() async throws {
    #expect(
      AnyProxyGroup.Kind.allCases == [.select, .urlTest, .fallback, .ssid, .loadBalance])
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      AnyProxyGroup.Kind.allCases, ["select", "url-test", "fallback", "ssid", "load-balance"]
    )
  )
  func rawRepresentableConformance(_ kind: AnyProxyGroup.Kind, _ rawValue: String) {
    #expect(kind.rawValue == rawValue)
    #expect(AnyProxyGroup.Kind(rawValue: rawValue) == kind)
    #expect(AnyProxyGroup.Kind(rawValue: "unknown") == nil)
  }
}

@Suite("AnyProxyGroup.ResourceTests", .tags(.proxyGroup))
struct AnyProxyGroupResourceTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let resource = AnyProxyGroup.Resource()
    #expect(resource.source == .cache)
    #expect(resource.externalProxiesURL == nil)
    #expect(resource.externalProxiesAutoUpdateTimeInterval == 86400)
  }
}

@Suite("AnyProxyGroup.Resource.SourceTests", .tags(.proxyGroup))
struct AnyProxyGroupResourceSourceTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(AnyProxyGroup.Resource.Source.allCases == [.cache, .query])
  }
}

@Suite("V1_AnyProxyGroup.MeasurementTests", .tags(.proxyGroup))
struct AnyProxyGroupMeasurementTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let transactionMetrics = TransactionMetrics()
    let measurement = AnyProxyGroup.Measurement(transactionMetrics: transactionMetrics)
    #expect(measurement.url == nil)
    #expect(measurement.transactionMetricsExpiryInterval == 600.0)
    #expect(measurement.timeout == 5.0)
    #expect(measurement.tolerance == 100)
    #expect(measurement.transactionMetrics == transactionMetrics)
  }
}
