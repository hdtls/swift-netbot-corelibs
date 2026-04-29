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

@Suite(.tags(.proxy)) struct AnyProxyTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let measurement = AnyProxy.Measurement()
    let proxy = AnyProxy(name: "sample", measurement: measurement)
    #expect(proxy.name == "sample")
    #expect(proxy.source == .userDefined)
    #expect(proxy.kind == .http)
    #expect(proxy.serverAddress == "")
    #expect(proxy.port == 0)
    #expect(proxy.username == "")
    #expect(proxy.passwordReference == "")
    #expect(proxy.alpn == "")
    #expect(!proxy.authenticationRequired)
    #expect(proxy.algorithm == .aes128Gcm)
    #expect(proxy.obfuscation == .init())
    #expect(proxy.measurement == measurement)
    #expect(proxy.tls == .init())
    #expect(proxy.ws == .init())
    #expect(proxy.engress == .init())
    #expect(!proxy.allowUDPRelay)
    #expect(!proxy.isTFOEnabled)
    #expect(!proxy.forceHTTPTunneling)
    #expect(!proxy.dontAlertError)
  }
}

@Suite("AnyProxy.KindTests", .tags(.proxy))
struct AnyProxyKindTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      AnyProxy.Kind.allCases,
      [
        "DIRECT", "REJECT-TINYGIF", "REJECT", "HTTPS", "HTTP", "SOCKS5 over TLS", "SOCKS5",
        "Shadowsocks", "VMESS",
      ]
    )
  )
  func localizedName(_ kind: AnyProxy.Kind, _ localizedName: String) {
    #expect(kind.localizedName == localizedName)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      AnyProxy.Kind.allCases,
      [
        "direct", "reject-tinygif", "reject", "https", "http", "socks5-over-tls", "socks5", "ss",
        "vmess",
      ]
    )
  )
  func rawRepresentableConformance(_ kind: AnyProxy.Kind, _ rawValue: String) {
    #expect(kind.rawValue == rawValue)
    #expect(AnyProxy.Kind(rawValue: rawValue) == kind)
    #expect(AnyProxy.Kind(rawValue: "unknown") == nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      AnyProxy.Kind.allCases, [false, false, false, true, true, true, true, true, true])
  )
  func isProxy(_ kind: AnyProxy.Kind, _ isProxy: Bool) {
    #expect(kind.isProxyable == isProxy)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      AnyProxy.Kind.allCases, [false, false, false, true, false, true, false, false, true]
    )
  )
  func supportTLSSettings(_ kind: AnyProxy.Kind, _ supported: Bool) {
    #expect(kind.supportTLSSettings == supported)
  }
}

@Suite("AnyProxy.EgressTests", .tags(.proxy))
struct AnyProxyEngressTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let engress = AnyProxy.Engress()
    #expect(engress.interfaceName == "")
    #expect(!engress.backToDefaultIfNICUnavailable)
    #expect(engress.packetToS == 0)
    #expect(engress.versionStrategy == .dual)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    "AnyProxy.Egress.VersionStrategy RawRepresentable Conformance",
    arguments: zip(AnyProxy.Engress.VersionStrategy.allCases, ["v4", "v6", "dual"]))
  func versionStrategyRawRepresentableConformance(
    _ strategy: AnyProxy.Engress.VersionStrategy, _ rawValue: String
  ) {
    #expect(strategy.rawValue == rawValue)
    #expect(AnyProxy.Engress.VersionStrategy(rawValue: rawValue) == strategy)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test("AnyProxy.Egress.VersionStrategy CaseIterable Conformance")
  func versionStrategyCaseIterableConformance() {
    #expect(AnyProxy.Engress.VersionStrategy.allCases == [.v4, .v6, .dual])
  }
}

@Suite("AnyProxy.MeasurementTests", .tags(.proxy))
struct AnyProxyMeasurementTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let transactionMetrics = TransactionMetrics()
    let measurement = AnyProxy.Measurement(transactionMetrics: transactionMetrics)
    #expect(measurement.url == nil)
    #expect(measurement.transactionMetrics == transactionMetrics)
  }
}

@Suite("AnyProxy.ObfuscationTests", .tags(.proxy))
struct AnyProxyObfuscationTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let obfuscation = AnyProxy.Obfuscation()
    #expect(!obfuscation.isEnabled)
    #expect(obfuscation.strategy == .http)
    #expect(obfuscation.hostname == "")
  }
}

@Suite("AnyProxy.Obfuscation.StrategyTests", .tags(.proxy))
struct AnyProxyObfuscationStrategyTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: zip(AnyProxy.Obfuscation.Strategy.allCases, [1, 2]))
  func optionSetConformance(_ strategy: AnyProxy.Obfuscation.Strategy, _ rawValue: Int) {
    #expect(strategy.rawValue == rawValue)
    #expect(AnyProxy.Obfuscation.Strategy(rawValue: rawValue) == strategy)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: zip(AnyProxy.Obfuscation.Strategy.allCases, ["HTTP", "TLS"]))
  func localizedName(_ strategy: AnyProxy.Obfuscation.Strategy, _ localizedName: String) {
    #expect(strategy.localizedName == localizedName)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(AnyProxy.Obfuscation.Strategy.allCases == [.http, .tls])
  }
}

@Suite("AnyProxy.SourceTests", .tags(.proxy))
struct AnyProxySourceTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() {
    #expect(AnyProxy.Source.allCases == [.builtin, .userDefined, .externalResource])
  }
}

@Suite("AnyProxy.TLSTests", .tags(.proxy))
struct AnyProxyTLSTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let tls = AnyProxy.TLS()
    #expect(!tls.isEnabled)
    #expect(!tls.skipCertificateVerification)
    #expect(tls.sni == "")
    #expect(tls.certificatePinning == "")
  }
}

@Suite("AnyProxy.WebSocketTests", .tags(.proxy))
struct AnyProxyWebSocketTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let ws = AnyProxy.WebSocket()
    #expect(!ws.isEnabled)
    #expect(ws.uri == "/")
    #expect(ws.additionalHTTPFields == nil)
  }
}
