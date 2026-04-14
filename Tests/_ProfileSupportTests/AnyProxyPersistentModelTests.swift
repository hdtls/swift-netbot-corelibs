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

#if canImport(SwiftData)
  import SwiftData
  import Testing

  @testable import _ProfileSupport

  @Suite("V1._AnyProxyTests", .tags(.swiftData, .schema, .proxy))
  struct V1_AnyProxyTests {

    var modelContainer: Any = 0

    init() throws {
      if #available(SwiftStdlib 5.9, *) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema: Schema = Schema(versionedSchema: _VersionedSchema.self)
        modelContainer = try ModelContainer(for: schema, configurations: configuration)
      }
    }

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValue() async throws {
      let proxy = V1._AnyProxy()
      //      #expect(proxy.name == "sample")
      #expect(proxy.source == AnyProxy.Source.userDefined.rawValue)
      #expect(proxy.kind == .http)
      #expect(proxy.serverAddress == "")
      #expect(proxy.port == 0)
      #expect(proxy.username == nil)
      #expect(proxy.passwordReference == nil)
      #expect(proxy.alpn == nil)
      #expect(!proxy.authenticationRequired)
      #expect(proxy.algorithm == .aes128Gcm)
      #expect(proxy.obfuscation == .init())
      //      #expect(proxy.measurement == measurement)
      #expect(proxy.tls == .init())
      #expect(proxy.ws == .init())
      #expect(proxy.engress == .init())
      #expect(!proxy.allowUDPRelay)
      #expect(!proxy.isTFOEnabled)
      #expect(!proxy.forceHTTPTunneling)
      #expect(!proxy.dontAlertError)
    }

    @available(SwiftStdlib 5.9, *)
    @Test("AnyProxy.init(persistentModel:)")
    func initWithPersistentModel() {
      let persistentModel = V1._AnyProxy()
      let proxy = AnyProxy(persistentModel: persistentModel)

      #expect(proxy.name == persistentModel.name)
      #expect(proxy.source == .init(rawValue: persistentModel.source)!)
      #expect(proxy.kind == persistentModel.kind)
      #expect(proxy.serverAddress == "")
      #expect(proxy.port == 0)
      #expect(proxy.username == "")
      #expect(proxy.passwordReference == "")
      #expect(proxy.alpn == "")
      #expect(proxy.authenticationRequired == persistentModel.authenticationRequired)
      #expect(proxy.algorithm == persistentModel.algorithm)
      #expect(proxy.obfuscation == persistentModel.obfuscation)
      #expect(proxy.measurement == persistentModel.measurement)
      #expect(proxy.tls == persistentModel.tls)
      #expect(proxy.ws == persistentModel.ws)
      #expect(proxy.engress == persistentModel.engress)
      #expect(proxy.allowUDPRelay == persistentModel.allowUDPRelay)
      #expect(proxy.isTFOEnabled == persistentModel.isTFOEnabled)
      #expect(proxy.forceHTTPTunneling == persistentModel.forceHTTPTunneling)
      #expect(proxy.dontAlertError == persistentModel.dontAlertError)
      #expect(proxy.creationDate == persistentModel.creationDate)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func mergeValues() async throws {
      let persistentModel = V1._AnyProxy()
      let proxy = AnyProxy()
      persistentModel.mergeValues(proxy)

      #expect(persistentModel.name == proxy.name)
      #expect(persistentModel.source == proxy.source.rawValue)
      #expect(persistentModel.kind == proxy.kind)
      #expect(persistentModel.serverAddress == proxy.serverAddress)
      #expect(persistentModel.port == proxy.port)
      #expect(persistentModel.username == proxy.username)
      #expect(persistentModel.passwordReference == proxy.passwordReference)
      #expect(persistentModel.alpn == proxy.alpn)
      #expect(persistentModel.authenticationRequired == proxy.authenticationRequired)
      #expect(persistentModel.algorithm == proxy.algorithm)
      #expect(persistentModel.obfuscation == proxy.obfuscation)
      #expect(persistentModel.measurement == proxy.measurement)
      #expect(persistentModel.tls == proxy.tls)
      #expect(persistentModel.ws == proxy.ws)
      #expect(persistentModel.engress == proxy.engress)
      #expect(persistentModel.allowUDPRelay == proxy.allowUDPRelay)
      #expect(persistentModel.isTFOEnabled == proxy.isTFOEnabled)
      #expect(persistentModel.forceHTTPTunneling == proxy.forceHTTPTunneling)
      #expect(persistentModel.dontAlertError == proxy.dontAlertError)
    }
  }

  @Suite("V1._AnyProxy.KindTests", .tags(.swiftData, .schema, .proxy))
  struct V1_AnyProxyKindTests {

    @available(SwiftStdlib 5.9, *)
    @Test(
      arguments: zip(
        V1._AnyProxy.Kind.allCases,
        [
          "DIRECT", "REJECT-TINYGIF", "REJECT", "HTTPS", "HTTP", "SOCKS5 over TLS", "SOCKS5",
          "Shadowsocks", "VMESS",
        ])
    )
    func localizedName(_ kind: V1._AnyProxy.Kind, _ localizedName: String) async throws {
      #expect(kind.localizedName == localizedName)
    }

    @available(SwiftStdlib 5.9, *)
    @Test(
      arguments: zip(
        V1._AnyProxy.Kind.allCases,
        [
          "direct", "reject-tinygif", "reject", "https", "http", "socks5-over-tls", "socks5",
          "ss", "vmess",
        ])
    )
    func rawRepresentableConformance(_ kind: V1._AnyProxy.Kind, _ rawValue: String) async throws {
      #expect(kind.rawValue == rawValue)
      #expect(V1._AnyProxy.Kind(rawValue: rawValue) == kind)
      #expect(V1._AnyProxy.Kind(rawValue: "unknown") == nil)
    }

    @available(SwiftStdlib 5.9, *)
    @Test(
      arguments: zip(
        V1._AnyProxy.Kind.allCases, [false, false, false, true, true, true, true, true, true]
      )
    )
    func isProxy(_ kind: V1._AnyProxy.Kind, _ isProxy: Bool) {
      #expect(kind.isProxyable == isProxy)
    }

    @available(SwiftStdlib 5.9, *)
    @Test(
      arguments: zip(
        V1._AnyProxy.Kind.allCases, [false, false, false, true, false, true, false, false, true]
      )
    )
    func supportTLSSettings(_ kind: V1._AnyProxy.Kind, _ supportTLSSettings: Bool) {
      #expect(kind.supportTLSSettings == supportTLSSettings)
    }
  }

  @Suite("V1._AnyProxy.ObfuscationTests", .tags(.swiftData, .schema, .proxy))
  struct V1_AnyProxyObfuscationTests {

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValue() async throws {
      let obfuscation = V1._AnyProxy.Obfuscation()
      #expect(!obfuscation.isEnabled)
      #expect(obfuscation.strategy == .http)
      #expect(obfuscation.hostname == "")
    }
  }

  @Suite("V1._AnyProxy.Obfuscation.StrategyTests", .tags(.swiftData, .schema, .proxy))
  struct V1_AnyProxyObfuscationStrategyTests {

    @available(SwiftStdlib 5.9, *)
    @Test(arguments: zip(V1._AnyProxy.Obfuscation.Strategy.allCases, [1, 2]))
    func optionSetConformance(_ strategy: V1._AnyProxy.Obfuscation.Strategy, _ rawValue: Int) {
      #expect(strategy.rawValue == rawValue)
      #expect(V1._AnyProxy.Obfuscation.Strategy(rawValue: rawValue) == strategy)
    }

    @available(SwiftStdlib 5.9, *)
    @Test(arguments: zip(V1._AnyProxy.Obfuscation.Strategy.allCases, ["HTTP", "TLS"]))
    func localizedName(_ strategy: V1._AnyProxy.Obfuscation.Strategy, _ localizedName: String) {
      #expect(strategy.localizedName == localizedName)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func caseIterableConformance() async throws {
      #expect(V1._AnyProxy.Obfuscation.Strategy.allCases == [.http, .tls])
    }
  }

  @Suite("V1._AnyProxy.MeasurementTests", .tags(.swiftData, .schema, .proxy))
  struct V1_AnyProxyMeasurementTests {

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValue() async throws {
      let transactionMetrics = TransactionMetrics()
      let measurement = V1._AnyProxy.Measurement(transactionMetrics: transactionMetrics)
      #expect(measurement.url == nil)
      #expect(measurement.transactionMetrics == transactionMetrics)
    }
  }

  @Suite("V1._AnyProxy.TLSTests", .tags(.swiftData, .schema, .proxy))
  struct V1_AnyProxyTLSTests {

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValue() async throws {
      let tls = V1._AnyProxy.TLS()
      #expect(!tls.isEnabled)
      #expect(!tls.skipCertificateVerification)
      #expect(tls.sni == "")
      #expect(tls.certificatePinning == "")
    }
  }

  @Suite("V1._AnyProxy.WebSocketTests", .tags(.swiftData, .schema, .proxy))
  struct V1_AnyProxyWebSocketTests {

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValue() async throws {
      let ws = V1._AnyProxy.WebSocket()
      #expect(!ws.isEnabled)
      #expect(ws.uri == "/")
      #expect(ws.additionalHTTPFields == nil)
    }
  }

  @Suite("V1._AnyProxy.EngressTests", .tags(.swiftData, .schema, .proxy))
  struct V1_AnyProxyEngressTests {

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValue() async throws {
      let engress = V1._AnyProxy.Engress()
      #expect(engress.interfaceName == "")
      #expect(!engress.backToDefaultIfNICUnavailable)
      #expect(engress.packetToS == 0)
      #expect(engress.versionStrategy == .dual)
    }

    @available(SwiftStdlib 5.9, *)
    @Test(
      "V1._AnyProxy.Engress.VersionStrategy RawRepresentable conformance",
      arguments: zip(V1._AnyProxy.Engress.VersionStrategy.allCases, ["v4", "v6", "dual"]))
    func versionStrategyRawRepresentableConformance(
      _ strategy: V1._AnyProxy.Engress.VersionStrategy, _ rawValue: String
    ) async throws {
      #expect(strategy.rawValue == rawValue)
      #expect(V1._AnyProxy.Engress.VersionStrategy(rawValue: rawValue) == strategy)
    }

    @available(SwiftStdlib 5.9, *)
    @Test("V1._AnyProxy.Engress.VersionStrategy CaseIterable conformance")
    func versionStrategyCaseIterableConformance() async throws {
      #expect(V1._AnyProxy.Engress.VersionStrategy.allCases == [.v4, .v6, .dual])
    }
  }
#endif
