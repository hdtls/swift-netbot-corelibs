//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

#if swift(>=6.3) || canImport(Darwin)
  import NEAddressProcessing
  import Testing

  @testable import AnlzrReports

  #if canImport(FoundationEssentials)
    import FoundationEssentials
  #else
    import Foundation
  #endif

  @Suite struct V1_EstablishmentReportTests {

    @available(SwiftStdlib 5.9, *)
    @Test func resolutionPropertyInitialValues() async throws {
      let resolution = V1._EstablishmentReport.Resolution.init(
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

    @available(SwiftStdlib 5.9, *)
    @Test func resolutionHashableConformance() async throws {
      let resolution = V1._EstablishmentReport.Resolution.init(
        source: .query, duration: 1.0, endpointCount: 1,
        successfulEndpoint: .hostPort(host: "127.0.0.1", port: 1111),
        preferredEndpoint: .hostPort(host: "127.0.0.1", port: 1111), dnsProtocol: .tcp)
      let expected = resolution

      #expect(resolution == expected)

      let resolutions = Set<V1._EstablishmentReport.Resolution>([resolution, expected])
      #expect(resolutions == [resolution])
    }

    @available(SwiftStdlib 5.9, *)
    @Test func resolutionCodableConformance() async throws {
      let resolution = V1._EstablishmentReport.Resolution.init(
        source: .query, duration: 1.0, endpointCount: 1,
        successfulEndpoint: .hostPort(host: "127.0.0.1", port: 1111),
        preferredEndpoint: .hostPort(host: "127.0.0.1", port: 1111), dnsProtocol: .tcp)

      let data = try JSONEncoder().encode(resolution)
      let result = try JSONDecoder().decode(V1._EstablishmentReport.Resolution.self, from: data)
      #expect(result == resolution)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func mutateResolutionSuccessfulEndpoint() async throws {
      let address = Address.hostPort(host: "1.1.1.1", port: 443)
      var resolution = V1._EstablishmentReport.Resolution(
        source: .cache, duration: 0, endpointCount: 0,
        successfulEndpoint: .unix(path: "/var/run/tmp.socks"),
        preferredEndpoint: .unix(path: "/var/run/tmp.socks"), dnsProtocol: .udp)
      resolution.successfulEndpoint = address
      #expect(resolution.successfulEndpoint == address)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func mutateResolutionPreferredEndpoint() async throws {
      let address = Address.hostPort(host: "1.1.1.1", port: 443)
      var resolution = V1._EstablishmentReport.Resolution(
        source: .cache, duration: 0, endpointCount: 0,
        successfulEndpoint: .unix(path: "/var/run/tmp.socks"),
        preferredEndpoint: .unix(path: "/var/run/tmp.socks"), dnsProtocol: .udp)
      resolution.preferredEndpoint = address
      #expect(resolution.preferredEndpoint == address)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func propertyInitialValues() async throws {
      let report = V1._EstablishmentReport()

      #expect(report._duration == 0.0)
      #expect(report.duration == .seconds(0))
      #expect(report.attemptStartedAfterInterval == 0.0)
      #expect(report.previousAttemptCount == 0)
      #expect(report.sourceEndpoint == nil)
      #expect(report.destinationEndpoint == nil)
      #expect(!report.usedProxy)
      #expect(report.resolutions == [])
    }

    @available(SwiftStdlib 5.9, *)
    @Test func destinationEndpoint() async throws {
      let report = V1._EstablishmentReport()
      #expect(report.destinationEndpoint == nil)

      report.resolutions = [
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
      ]
      #expect(report.destinationEndpoint == .hostPort(host: "127.0.0.1", port: 443))
    }

    @available(SwiftStdlib 5.9, *)
    @Test func destinationEndpointWhenUseProxyIsEnabled() async throws {
      let report = V1._EstablishmentReport()
      #expect(report.destinationEndpoint == nil)
      report.proxyEndpoint = .hostPort(host: "127.0.0.", port: 443)
      #expect(report.destinationEndpoint == nil)
      report.usedProxy = true
      #expect(report.destinationEndpoint == report.proxyEndpoint)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func mutateSourceEndpoint() async throws {
      let address = Address.hostPort(host: "example.com", port: 443)
      let establishmentReport = V1._EstablishmentReport()
      establishmentReport.sourceEndpoint = address
      #expect(establishmentReport.sourceEndpoint == address)

      establishmentReport.sourceEndpoint = nil
      #expect(establishmentReport.sourceEndpoint == nil)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func mutateProxyEndpoint() async throws {
      let address = Address.hostPort(host: "example.com", port: 443)
      let establishmentReport = V1._EstablishmentReport()
      establishmentReport.proxyEndpoint = address
      #expect(establishmentReport.proxyEndpoint == address)

      establishmentReport.proxyEndpoint = nil
      #expect(establishmentReport.proxyEndpoint == nil)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func mergeValues() async throws {
      let data = EstablishmentReport(
        duration: 1,
        attemptStartedAfterInterval: 1,
        previousAttemptCount: 4,
        sourceEndpoint: .hostPort(host: "0.0.0.0", port: 0),
        usedProxy: true,
        proxyEndpoint: .hostPort(host: "0.0.0.0", port: 0),
        resolutions: [
          .init(
            source: .cache, duration: 0.5, endpointCount: 1,
            successfulEndpoint: .hostPort(host: "127.0.0.1", port: 443),
            preferredEndpoint: .hostPort(host: "127.0.0.1", port: 443), dnsProtocol: .udp)
        ])
      let establishmentReport = V1._EstablishmentReport()
      establishmentReport.mergeValues(data)
      #expect(establishmentReport.duration == data.duration)
      #expect(establishmentReport._duration == data._duration)
      #expect(establishmentReport.attemptStartedAfterInterval == data.attemptStartedAfterInterval)
      #expect(establishmentReport.previousAttemptCount == data.previousAttemptCount)
      #expect(establishmentReport.sourceEndpoint == data.sourceEndpoint)
      #expect(establishmentReport.usedProxy == data.usedProxy)
      #expect(establishmentReport.proxyEndpoint == data.proxyEndpoint)
      #expect(establishmentReport.resolutions.count == data.resolutions.count)
    }
  }
#endif
