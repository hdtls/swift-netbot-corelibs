// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Testing

@testable import Dashboard

@Suite struct ConnectionAddressReportTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func initWithAllParameters() {
    let report = ConnectionAddressReport(
      hostname: "example.com",
      port: 8080,
      localIPAddress: "192.168.1.1",
      remoteIPAddress: "93.184.216.34",
      remoteIPAddressRegion: "US",
      remoteIPAddressASN: "AS12345",
      remoteIPAddressASO: "ASO6789"
    )

    #expect(report.hostname == "example.com", "Hostname should match")
    #expect(report.port == 8080, "Port should match")
    #expect(report.localIPAddress == "192.168.1.1", "Local IP Address should match")
    #expect(report.remoteIPAddress == "93.184.216.34", "Remote IP Address should match")
    #expect(report.remoteIPAddressRegion == "US", "Remote IP Address Region should match")
    #expect(report.remoteIPAddressASN == "AS12345", "Remote IP Address ASN should match")
    #expect(report.remoteIPAddressASO == "ASO6789", "Remote IP Address ASO should match")
  }

  // Test default values when parameters are not passed
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func initWithDefaultValues() {
    let report = ConnectionAddressReport(
      hostname: "example.com",
      port: 8080
    )

    #expect(report.hostname == "example.com", "Hostname should match")
    #expect(report.port == 8080, "Port should match")
    #expect(report.localIPAddress == "N/A", "Default local IP Address should be 'N/A'")
    #expect(report.remoteIPAddress == "N/A", "Default remote IP Address should be 'N/A'")
    #expect(
      report.remoteIPAddressRegion == "N/A", "Default remote IP Address Region should be 'N/A'")
    #expect(report.remoteIPAddressASN == "N/A", "Default remote IP Address ASN should be 'N/A'")
    #expect(report.remoteIPAddressASO == "N/A", "Default remote IP Address ASO should be 'N/A'")
  }

  // Test equality (== operator) and hashing
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func equalityAndHashing() {
    let report1 = ConnectionAddressReport(
      hostname: "example.com",
      port: 8080,
      localIPAddress: "192.168.1.1",
      remoteIPAddress: "93.184.216.34",
      remoteIPAddressRegion: "US",
      remoteIPAddressASN: "AS12345",
      remoteIPAddressASO: "ASO6789"
    )

    let report2 = ConnectionAddressReport(
      hostname: "example.com",
      port: 8080,
      localIPAddress: "192.168.1.1",
      remoteIPAddress: "93.184.216.34",
      remoteIPAddressRegion: "US",
      remoteIPAddressASN: "AS12345",
      remoteIPAddressASO: "ASO6789"
    )

    let report3 = ConnectionAddressReport(
      hostname: "example.org",
      port: 8080
    )

    // Test equality
    #expect(report1 == report2, "Reports should be equal")
    #expect(report1 != report3, "Reports should not be equal")

    // Test hashability
    let set = Set([report1, report2, report3])
    #expect(set.count == 2, "Set should contain only 2 unique reports")
  }

  // Test Codable conformance (encode and decode)
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func testCodable() throws {
    let report = ConnectionAddressReport(
      hostname: "example.com",
      port: 8080,
      localIPAddress: "192.168.1.1",
      remoteIPAddress: "93.184.216.34",
      remoteIPAddressRegion: "US",
      remoteIPAddressASN: "AS12345",
      remoteIPAddressASO: "ASO6789"
    )

    let result = try JSONDecoder().decode(
      ConnectionAddressReport.self, from: JSONEncoder().encode(report))

    #expect(result == report)
  }
}
