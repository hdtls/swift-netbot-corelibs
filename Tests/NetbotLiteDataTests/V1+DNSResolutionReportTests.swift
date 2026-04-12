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

import NEAddressProcessing
import Testing

@testable import NetbotLiteData

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  import SwiftData
#endif

@Suite struct V1_DNSResolutionReportTests {

  @available(SwiftStdlib 5.9, *)
  @Test func persistentModelTypealias() {
    #expect(DNSResolutionReport.PersistentModel.self == V1._DNSResolutionReport.self)
  }

  @available(SwiftStdlib 5.9, *)
  @Test func mergeValues() {
    let data = DNSResolutionReport(
      duration: 12.5,
      resolutions: [
        DNSResolutionReport.Resolution(
          source: .query,
          duration: 3.5,
          dnsProtocol: .udp,
          endpoints: [
            Address.hostPort(host: "2.2.2.2", port: 53),
            Address.hostPort(host: "3.3.3.3", port: 53),
          ]
        ),
        DNSResolutionReport.Resolution(
          source: .cache,
          duration: 4.75,
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
