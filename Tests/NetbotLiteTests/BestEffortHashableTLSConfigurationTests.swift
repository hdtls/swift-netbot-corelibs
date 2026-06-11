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

import NIOSSL
import Testing

@testable import NetbotLite

@Suite struct BestEffortHashableTLSConfigurationTests {
  @available(SwiftStdlib 6.0, *)
  @Test("Identical TLSConfiguration should be equal and hash the same")
  func hashableConformance() async throws {
    let cfg1 = NIOSSL.TLSConfiguration.makeClientConfiguration()
    let cfg2 = NIOSSL.TLSConfiguration.makeClientConfiguration()
    let wr1 = BestEffortHashableTLSConfiguration(wrapping: cfg1)
    let wr2 = BestEffortHashableTLSConfiguration(wrapping: cfg2)
    #expect(wr1 == wr2, "BestEffortHashableTLSConfiguration equality failed for identical configs")
    #expect(wr1.hashValue == wr2.hashValue, "Hash values should match for identical configs")
  }

  @available(SwiftStdlib 6.0, *)
  @Test("Different TLSConfiguration should not be equal and should have different hashes")
  func differentConfigurations() async throws {
    let cfg1 = NIOSSL.TLSConfiguration.makeClientConfiguration()
    var cfg2 = NIOSSL.TLSConfiguration.makeClientConfiguration()
    cfg2.minimumTLSVersion = .tlsv12  // Mutate one property
    let wr1 = BestEffortHashableTLSConfiguration(wrapping: cfg1)
    let wr2 = BestEffortHashableTLSConfiguration(wrapping: cfg2)
    #expect(
      wr1 != wr2, "BestEffortHashableTLSConfiguration should not be equal for different configs")
    #expect(wr1.hashValue != wr2.hashValue, "Hash values should differ for different configs")
  }

  @available(SwiftStdlib 6.0, *)
  @Test("BestEffortHashableTLSConfiguration is usable in Set and Dictionary")
  func hashableInSetAndDict() async throws {
    let cfg = NIOSSL.TLSConfiguration.makeClientConfiguration()
    let wr = BestEffortHashableTLSConfiguration(wrapping: cfg)
    var set: Set<BestEffortHashableTLSConfiguration> = []
    set.insert(wr)
    #expect(set.contains(wr), "Set should contain the inserted wrapper")
    var dict: [BestEffortHashableTLSConfiguration: String] = [:]
    dict[wr] = "value"
    #expect(dict[wr] == "value", "Should retrieve value using the hashable wrapper")
  }
}
