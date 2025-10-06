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
import NIOCore
import Testing

@testable import _NEAnalytics

struct AvailableIPPoolTests {

  @Test(arguments: [
    "1111.1/12",
    "as.1/12",
    "192.168/16",
    "192.168.1.1.1/16",
    "192.168.1.1/33",
    "192.168.1.1/z",
  ])
  func validatingIPCIDR(_ cidr: String) async throws {
    #expect(AvailableIPPool(uncheckedBounds: cidr) == nil)
  }

  @Test func bypassRangeBoundary() async throws {
    var pool = try #require(AvailableIPPool(uncheckedBounds: "192.168.0.1/16"))
    #expect(pool.lower == IPv4Address("192.168.0.0")!)
    #expect(pool.upper == IPv4Address("192.168.255.255")!)
    #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.0.1"))
    pool.store(pool.upper)
    #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.0.1"))

    pool = AvailableIPPool(bounds: (IPv4Address("192.168.0.0")!, IPv4Address("192.168.255.255")!))
    #expect(pool.lower == IPv4Address("192.168.0.0")!)
    #expect(pool.upper == IPv4Address("192.168.255.255")!)
    #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.0.1"))
    pool.store(pool.upper)
    #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.0.1"))
  }

  @Test func loadThenWrappingIncrement() async throws {
    let availablePools = [
      try #require(AvailableIPPool(uncheckedBounds: "192.168.0.1/16")),
      AvailableIPPool(
        bounds: (IPv4Address("192.168.0.0")!, IPv4Address("192.168.255.255")!)
      ),
    ]
    for pool in availablePools {
      #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.0.1"))
      #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.0.2"))
      #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.0.3"))

      pool.store(IPv4Address("192.168.255.255")!)
      #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.0.1"))

      pool.store(IPv4Address("192.168.0.255")!)
      #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.0.255"))
      #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.1.0"))
      #expect(pool.loadThenWrappingIncrement() == IPv4Address("192.168.1.1"))
    }
  }

  @Test func contains() async throws {
    let p = AvailableIPPool(uncheckedBounds: "198.18.0.1/15")!
    let na0 = IPv4Address("198.18.1.1")!
    let na1 = IPv4Address("198.20.0.1")!

    #expect(p.contains(na0))
    #expect(!p.contains(na1))
  }
}
