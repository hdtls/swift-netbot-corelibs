// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NEAddressProcessing
import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct EstablishmentReportTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func resolutionSourceHashableConformance() async throws {
    let source = EstablishmentReport.Resolution.Source.query
    #expect(source == .query)

    let dnsProtocols = Set<EstablishmentReport.Resolution.Source>([.query, .cache, .query])
    #expect(dnsProtocols == [.query, .cache])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func resolutionSourceCodableConformance() async throws {
    let source = EstablishmentReport.Resolution.Source.query

    let data = try JSONEncoder().encode(source)
    let jsonObject = String(data: data, encoding: .utf8)
    #expect(jsonObject == "\"query\"")

    let result = try JSONDecoder().decode(EstablishmentReport.Resolution.Source.self, from: data)
    #expect(result == source)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func resolutionDNSProtocolHashableConformance() async throws {
    let dnsProtocol = EstablishmentReport.Resolution.DNSProtocol.tcp
    #expect(dnsProtocol == .tcp)

    let dnsProtocols = Set<EstablishmentReport.Resolution.DNSProtocol>([.tcp, .udp, .tcp])
    #expect(dnsProtocols == [.tcp, .udp])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func resolutionDNSProtocolCodableConformance() async throws {
    let dnsProtocol = EstablishmentReport.Resolution.DNSProtocol.tcp

    let data = try JSONEncoder().encode(dnsProtocol)
    let jsonObject = String(data: data, encoding: .utf8)
    #expect(jsonObject == "\"tcp\"")

    let result = try JSONDecoder().decode(
      EstablishmentReport.Resolution.DNSProtocol.self, from: data)
    #expect(result == dnsProtocol)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func resolutionPropertyInitialValues() async throws {
    let resolution = EstablishmentReport.Resolution.init(
      source: .query, duration: 1.0, endpointCount: 1,
      successfulEndpoint: .hostPort(host: "127.0.0.1", port: 1111),
      preferredEndpoint: .hostPort(host: "127.0.0.1", port: 1111), dnsProtocol: .tcp)
    #expect(resolution.source == .query)
    #expect(resolution._duration == 1.0)
    #expect(resolution.duration == .seconds(1))
    #expect(resolution.endpointCount == 1)
    #expect(resolution.successfulEndpoint == .hostPort(host: "127.0.0.1", port: 1111))
    #expect(resolution.preferredEndpoint == .hostPort(host: "127.0.0.1", port: 1111))
    #expect(resolution.dnsProtocol == .tcp)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func resolutionHashableConformance() async throws {
    let resolution = EstablishmentReport.Resolution.init(
      source: .query, duration: 1.0, endpointCount: 1,
      successfulEndpoint: .hostPort(host: "127.0.0.1", port: 1111),
      preferredEndpoint: .hostPort(host: "127.0.0.1", port: 1111), dnsProtocol: .tcp)
    let expected = resolution

    #expect(resolution == expected)

    let resolutions = Set<EstablishmentReport.Resolution>([resolution, expected])
    #expect(resolutions == [resolution])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func resolutionCodableConformance() async throws {
    let resolution = EstablishmentReport.Resolution.init(
      source: .query, duration: 1.0, endpointCount: 1,
      successfulEndpoint: .hostPort(host: "127.0.0.1", port: 1111),
      preferredEndpoint: .hostPort(host: "127.0.0.1", port: 1111), dnsProtocol: .tcp)

    let data = try JSONEncoder().encode(resolution)
    let result = try JSONDecoder().decode(EstablishmentReport.Resolution.self, from: data)
    #expect(result == resolution)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValues() async throws {
    let report = EstablishmentReport()

    #expect(report._duration == 0.0)
    #expect(report.duration == .seconds(0))
    #expect(report.attemptStartedAfterInterval == 0.0)
    #expect(report.previousAttemptCount == 0)
    #expect(report.sourceEndpoint == nil)
    #expect(report.destinationEndpoint == nil)
    #expect(!report.usedProxy)
    #expect(report.resolutions == [])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func destinationEndpoint() async throws {
    var report = EstablishmentReport()
    #expect(report.destinationEndpoint == nil)

    report = EstablishmentReport(
      duration: 0,
      attemptStartedAfterInterval: 0,
      previousAttemptCount: 0,
      sourceEndpoint: nil,
      usedProxy: false,
      proxyEndpoint: nil,
      resolutions: [
        .init(
          source: .query,
          duration: 0,
          endpointCount: 1,
          successfulEndpoint: .hostPort(host: "127.0.0.1", port: 443),
          preferredEndpoint: .hostPort(host: "127.0.0.1", port: 443),
          dnsProtocol: .udp),
        .init(
          source: .query,
          duration: 0,
          endpointCount: 1,
          successfulEndpoint: .hostPort(host: "127.0.0.2", port: 443),
          preferredEndpoint: .hostPort(host: "127.0.0.2", port: 443),
          dnsProtocol: .udp),
      ])
    #expect(report.destinationEndpoint == .hostPort(host: "127.0.0.1", port: 443))
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func destinationEndpointWhenUseProxyIsEnabled() async throws {
    var report = EstablishmentReport(
      duration: 0,
      attemptStartedAfterInterval: 0,
      previousAttemptCount: 0,
      sourceEndpoint: nil,
      usedProxy: false,
      proxyEndpoint: .hostPort(host: "127.0.0.", port: 443),
      resolutions: []
    )
    #expect(report.destinationEndpoint == nil)

    report = EstablishmentReport(
      duration: 0,
      attemptStartedAfterInterval: 0,
      previousAttemptCount: 0,
      sourceEndpoint: nil,
      usedProxy: true,
      proxyEndpoint: .hostPort(host: "127.0.0.1", port: 443),
      resolutions: []
    )
    #expect(report.destinationEndpoint == report.proxyEndpoint)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hashableConformance() async throws {
    let report = EstablishmentReport()
    #expect(report == .init())

    let reports = Set<EstablishmentReport>([report, .init()])
    #expect(reports == [report])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func codableConformance() async throws {
    let report = EstablishmentReport()
    let data = try JSONEncoder().encode(report)
    let result = try JSONDecoder().decode(EstablishmentReport.self, from: data)
    #expect(result == report)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func persistentModel() {
    let source = EstablishmentReport.Model.self
    #expect(source == V1._EstablishmentReport.self)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func initializeEstablishmentReportFromPersistentModel() async throws {
    let persistentModel = V1._EstablishmentReport()
    persistentModel.resolutions = [
      .init(
        source: .cache, duration: 0.5, endpointCount: 1,
        successfulEndpoint: .hostPort(host: "127.0.0.1", port: 443),
        preferredEndpoint: .hostPort(host: "127.0.0.1", port: 443), dnsProtocol: .udp)
    ]
    let establishmentReport = EstablishmentReport(persistentModel: persistentModel)
    #expect(
      establishmentReport
        == EstablishmentReport(
          duration: 0,
          attemptStartedAfterInterval: 0,
          previousAttemptCount: 0,
          sourceEndpoint: nil,
          usedProxy: false,
          proxyEndpoint: nil,
          resolutions: [
            .init(
              source: .cache, duration: 0.5, endpointCount: 1,
              successfulEndpoint: .hostPort(host: "127.0.0.1", port: 443),
              preferredEndpoint: .hostPort(host: "127.0.0.1", port: 443), dnsProtocol: .udp)
          ]))
  }
}
