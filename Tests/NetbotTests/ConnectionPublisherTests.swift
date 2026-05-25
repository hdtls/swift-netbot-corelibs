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
import NIOCore
import NetbotDNS
import NetbotLiteData
import Testing

@testable import Netbot

#if canImport(Network)
  import Network
  import NIOTransportServices
#else
  import NIOPosix
#endif

struct ConnectionPublisherTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func failedToRunIfAddressAlreadyInUsed() async throws {
    let channel = try await ServerBootstrap(group: .shared)
      .bind(to: .init(ipAddress: "127.0.0.1", port: 0))
      .get()
    let address = try #require(try channel.localAddress?.asAddress())

    #if canImport(Network)
      await #expect(throws: NWError.posix(.EADDRINUSE)) {
        try await ConnectionPulse(group: .shared, address: address).run()
      }
    #else
      await #expect(throws: IOError.self) {
        try await ConnectionPulse(group: .shared, address: address).run()
      }
    #endif
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func shutdownGracefully() async throws {
    let publisher = ConnectionPulse(
      group: .shared, address: .hostPort(host: "127.0.0.1", port: .any))
    try await publisher.run()
    await #expect(throws: Never.self) {
      try await publisher.shutdownGracefully()
    }
  }
}
