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

import NEAddressProcessing
import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct V1_EstablishmentReportTests {

  @available(SwiftStdlib 6.0, *)
  @Test func resolutionPropertyInitialValues() async throws {
    let resolution = V1.EstablishmentReport.Resolution.init(
      source: .query, duration: .seconds(1.0), endpointCount: 1,
      successfulEndpoint: .hostPort(host: "127.0.0.1", port: 1111),
      preferredEndpoint: .hostPort(host: "127.0.0.1", port: 1111), dnsProtocol: .tcp)
    #expect(resolution.source == .query)
    #expect(resolution.duration == .seconds(1))
    #expect(resolution.endpointCount == 1)
    #expect(resolution.successfulEndpoint == .hostPort(host: "127.0.0.1", port: 1111))
    #expect(resolution.preferredEndpoint == .hostPort(host: "127.0.0.1", port: 1111))
    #expect(resolution.dnsProtocol == .tcp)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func resolutionHashableConformance() async throws {
    let resolution = V1.EstablishmentReport.Resolution.init(
      source: .query, duration: .seconds(1.0), endpointCount: 1,
      successfulEndpoint: .hostPort(host: "127.0.0.1", port: 1111),
      preferredEndpoint: .hostPort(host: "127.0.0.1", port: 1111), dnsProtocol: .tcp)
    let expected = resolution

    #expect(resolution == expected)

    let resolutions = Set<V1.EstablishmentReport.Resolution>([resolution, expected])
    #expect(resolutions == [resolution])
  }

  @available(SwiftStdlib 6.0, *)
  @Test func resolutionCodableConformance() async throws {
    let resolution = V1.EstablishmentReport.Resolution.init(
      source: .query, duration: .seconds(1.0), endpointCount: 1,
      successfulEndpoint: .hostPort(host: "127.0.0.1", port: 1111),
      preferredEndpoint: .hostPort(host: "127.0.0.1", port: 1111), dnsProtocol: .tcp)

    let data = try JSONEncoder().encode(resolution)
    let result = try JSONDecoder().decode(V1.EstablishmentReport.Resolution.self, from: data)
    #expect(result == resolution)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mutateResolutionSuccessfulEndpoint() async throws {
    let address = Address.hostPort(host: "1.1.1.1", port: 443)
    var resolution = V1.EstablishmentReport.Resolution(
      source: .cache, duration: .zero, endpointCount: 0,
      successfulEndpoint: .unix(path: "/var/run/tmp.socks"),
      preferredEndpoint: .unix(path: "/var/run/tmp.socks"), dnsProtocol: .udp)
    resolution.successfulEndpoint = address
    #expect(resolution.successfulEndpoint == address)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mutateResolutionPreferredEndpoint() async throws {
    let address = Address.hostPort(host: "1.1.1.1", port: 443)
    var resolution = V1.EstablishmentReport.Resolution(
      source: .cache, duration: .zero, endpointCount: 0,
      successfulEndpoint: .unix(path: "/var/run/tmp.socks"),
      preferredEndpoint: .unix(path: "/var/run/tmp.socks"), dnsProtocol: .udp)
    resolution.preferredEndpoint = address
    #expect(resolution.preferredEndpoint == address)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValues() async throws {
    let report = V1.EstablishmentReport()

    #expect(report.duration == .zero)
    #expect(report.attemptStartedAfterInterval == 0.0)
    #expect(report.previousAttemptCount == 0)
    #expect(report.sourceEndpoint == nil)
    #expect(report.destinationEndpoint == nil)
    #expect(!report.usedProxy)
    #expect(report.resolutions == [])
  }

  @available(SwiftStdlib 6.0, *)
  @Test func destinationEndpoint() async throws {
    let report = V1.EstablishmentReport()
    #expect(report.destinationEndpoint == nil)

    report.resolutions = [
      .init(
        source: .query,
        duration: .zero,
        endpointCount: 1,
        successfulEndpoint: .hostPort(host: "127.0.0.1", port: 443),
        preferredEndpoint: .hostPort(host: "127.0.0.1", port: 443),
        dnsProtocol: .udp),
      .init(
        source: .query,
        duration: .zero,
        endpointCount: 1,
        successfulEndpoint: .hostPort(host: "127.0.0.2", port: 443),
        preferredEndpoint: .hostPort(host: "127.0.0.2", port: 443),
        dnsProtocol: .udp),
    ]
    #expect(report.destinationEndpoint == .hostPort(host: "127.0.0.1", port: 443))
  }

  @available(SwiftStdlib 6.0, *)
  @Test func destinationEndpointWhenUseProxyIsEnabled() async throws {
    let report = V1.EstablishmentReport()
    #expect(report.destinationEndpoint == nil)
    report.proxyEndpoint = .hostPort(host: "127.0.0.", port: 443)
    #expect(report.destinationEndpoint == nil)
    report.usedProxy = true
    #expect(report.destinationEndpoint == report.proxyEndpoint)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mutateSourceEndpoint() async throws {
    let address = Address.hostPort(host: "example.com", port: 443)
    let establishmentReport = V1.EstablishmentReport()
    establishmentReport.sourceEndpoint = address
    #expect(establishmentReport.sourceEndpoint == address)

    establishmentReport.sourceEndpoint = nil
    #expect(establishmentReport.sourceEndpoint == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mutateProxyEndpoint() async throws {
    let address = Address.hostPort(host: "example.com", port: 443)
    let establishmentReport = V1.EstablishmentReport()
    establishmentReport.proxyEndpoint = address
    #expect(establishmentReport.proxyEndpoint == address)

    establishmentReport.proxyEndpoint = nil
    #expect(establishmentReport.proxyEndpoint == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mergeValues() async throws {
    let data = EstablishmentReport(
      duration: .seconds(1),
      attemptStartedAfterInterval: 1,
      previousAttemptCount: 4,
      sourceEndpoint: .hostPort(host: "0.0.0.0", port: 0),
      usedProxy: true,
      proxyEndpoint: .hostPort(host: "0.0.0.0", port: 0),
      resolutions: [
        .init(
          source: .cache, duration: .seconds(0.5), endpointCount: 1,
          successfulEndpoint: .hostPort(host: "127.0.0.1", port: 443),
          preferredEndpoint: .hostPort(host: "127.0.0.1", port: 443), dnsProtocol: .udp)
      ])
    let establishmentReport = V1.EstablishmentReport()
    establishmentReport.mergeValues(data)
    #expect(establishmentReport.duration == data.duration)
    #expect(establishmentReport.attemptStartedAfterInterval == data.attemptStartedAfterInterval)
    #expect(establishmentReport.previousAttemptCount == data.previousAttemptCount)
    #expect(establishmentReport.sourceEndpoint == data.sourceEndpoint)
    #expect(establishmentReport.usedProxy == data.usedProxy)
    #expect(establishmentReport.proxyEndpoint == data.proxyEndpoint)
    #expect(establishmentReport.resolutions.count == data.resolutions.count)
  }
}

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  extension V1_EstablishmentReportTests {

    @available(SwiftStdlib 6.0, *)
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1.EstablishmentReport.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      let data = EstablishmentReport(
        duration: .seconds(12),
        attemptStartedAfterInterval: 1,
        previousAttemptCount: 3,
        sourceEndpoint: .hostPort(host: "127.0.0.1", port: 1233),
        usedProxy: true,
        proxyEndpoint: .hostPort(host: "123.44.2.123", port: 2345),
        resolutions: [
          .init(
            source: .cache,
            duration: .seconds(0.2),
            endpointCount: 1,
            successfulEndpoint: .hostPort(host: "123.44.2.2", port: 443),
            preferredEndpoint: .hostPort(host: "123.44.2.2", port: 443),
            dnsProtocol: .udp
          )
        ]
      )

      let model = V1.EstablishmentReport()
      model.mergeValues(data)
      modelContext.insert(model)

      let fetched = try modelContext.fetch(FetchDescriptor<V1.EstablishmentReport>()).first
      let persistentModel = try #require(fetched)
      let result = EstablishmentReport(persistentModel: persistentModel)
      #expect(result == data)
    }
  }
#endif
