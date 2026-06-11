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

@Suite struct V1_DNSResolutionReportTests {

  @available(SwiftStdlib 6.0, *)
  @Test func persistentModelTypealias() {
    #expect(DNSResolutionReport.Model.self == V1._DNSResolutionReport.self)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mergeValues() {
    let data = DNSResolutionReport(
      duration: .seconds(12.5),
      resolutions: [
        DNSResolutionReport.Resolution(
          source: .query,
          duration: .seconds(3.5),
          dnsProtocol: .udp,
          endpoints: [
            Address.hostPort(host: "2.2.2.2", port: 53),
            Address.hostPort(host: "3.3.3.3", port: 53),
          ]
        ),
        DNSResolutionReport.Resolution(
          source: .cache,
          duration: .seconds(4.75),
          dnsProtocol: .tcp,
          endpoints: [
            Address.hostPort(host: "4.4.4.4", port: 53)
          ]
        ),
      ]
    )

    let report = V1._DNSResolutionReport()
    report.mergeValues(data)

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

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData

  extension V1_DNSResolutionReportTests {

    @available(SwiftStdlib 6.0, *)
    @Test func query() async throws {
      SQL_initialized()

      let modelContainer = try ModelContainer(
        for: V1._DNSResolutionReport.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
      )
      let modelContext = ModelContext(modelContainer)

      let data = DNSResolutionReport(
        duration: .seconds(1),
        resolutions: [
          .init(
            source: .query, duration: .seconds(1), dnsProtocol: .udp,
            endpoints: [
              .hostPort(host: "123.34.23.94", port: 443)
            ])
        ])

      let model = V1._DNSResolutionReport()
      model.mergeValues(data)
      modelContext.insert(model)

      let fetched = try modelContext.fetch(FetchDescriptor<V1._DNSResolutionReport>()).first
      let persistentModel = try #require(fetched)
      let result = DNSResolutionReport(persistentModel: persistentModel)
      #expect(result == data)
    }
  }
#endif
