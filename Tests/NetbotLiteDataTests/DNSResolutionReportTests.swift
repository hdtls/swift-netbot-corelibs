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

import NEAddressProcessing
import Testing

@testable import NetbotLiteData

@Suite struct DNSResolutionReportTests {

  @Test func propertyInitialValues() {
    let report = DNSResolutionReport(duration: 0, resolutions: [])
    #expect(report.duration == .zero)
    #expect(report.resolutions.isEmpty)
    #expect(report.duration.seconds == report._duration)
  }

  @Test func resolutionComputedProperties() {
    let addresses = [
      Address.hostPort(host: "1.1.1.1", port: 53),
      Address.hostPort(host: "8.8.8.8", port: 53),
    ]
    let resolution = DNSResolutionReport.Resolution(
      source: .query,
      duration: 1.25,
      dnsProtocol: .udp,
      endpoints: addresses
    )

    #expect(resolution.endpointCount == 2)
    #expect(resolution.duration.seconds == 1.25)
    #expect(resolution.endpoints == addresses)
  }

  @Test func codableRoundTrip() throws {
    let resolutions = [
      DNSResolutionReport.Resolution(
        source: .query,
        duration: 0.5,
        dnsProtocol: .tcp,
        endpoints: [
          Address.hostPort(host: "9.9.9.9", port: 53),
          Address.hostPort(host: "1.0.0.1", port: 53),
        ]
      ),
      DNSResolutionReport.Resolution(
        source: .cache,
        duration: 0.75,
        dnsProtocol: .udp,
        endpoints: [
          Address.hostPort(host: "8.8.4.4", port: 53)
        ]
      ),
    ]
    let report = DNSResolutionReport(duration: 3.25, resolutions: resolutions)

    let encoder = JSONEncoder()
    let data = try encoder.encode(report)
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(DNSResolutionReport.self, from: data)

    #expect(decoded.duration == report.duration)
    #expect(decoded.resolutions.count == report.resolutions.count)

    for (original, decodedResolution) in zip(report.resolutions, decoded.resolutions) {
      #expect(decodedResolution.duration.seconds == original.duration.seconds)
      #expect(decodedResolution.source == original.source)
      #expect(decodedResolution.dnsProtocol == original.dnsProtocol)
      #expect(decodedResolution.endpoints == original.endpoints)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func dnsResolutionReportFromPersistentModel() throws {
    let persistent = V1._DNSResolutionReport()
    persistent._duration = 12.5
    persistent.resolutions = [
      V1._DNSResolutionReport.Resolution(
        source: .query,
        duration: 3.5,
        dnsProtocol: .udp,
        endpoints: [
          Address.hostPort(host: "2.2.2.2", port: 53),
          Address.hostPort(host: "3.3.3.3", port: 53),
        ]
      ),
      V1._DNSResolutionReport.Resolution(
        source: .cache,
        duration: 4.75,
        dnsProtocol: .tcp,
        endpoints: [
          Address.hostPort(host: "4.4.4.4", port: 53)
        ]
      ),
    ]

    let report = DNSResolutionReport(persistentModel: persistent)

    #expect(report.duration.seconds == 12.5)
    #expect(report.resolutions.count == 2)

    let first = report.resolutions[0]
    #expect(first.duration.seconds == 3.5)
    #expect(first.source == .query)
    #expect(first.dnsProtocol == .udp)
    #expect(
      first.endpoints == [
        Address.hostPort(host: "2.2.2.2", port: 53),
        Address.hostPort(host: "3.3.3.3", port: 53),
      ])

    let second = report.resolutions[1]
    #expect(second.duration.seconds == 4.75)
    #expect(second.source == .cache)
    #expect(second.dnsProtocol == .tcp)
    #expect(
      second.endpoints == [
        Address.hostPort(host: "4.4.4.4", port: 53)
      ])
  }
}
