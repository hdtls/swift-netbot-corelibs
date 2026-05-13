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

import Logging
import NEAddressProcessing
import NetbotLiteData
import Testing

@testable import NetbotLite

@Suite struct ConnectionTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func metadata() async throws {
    var connection = Connection(taskIdentifier: 0)
    connection.originalRequest = .init(address: .hostPort(host: "192.168.0.2", port: 45345))
    #expect(connection.metadata["Request"] == "#0 192.168.0.2:45345")

    connection = Connection(taskIdentifier: 0)
    connection.originalRequest = .init(address: .unix(path: "/var/tmp/sock.sock"))

    connection.originalRequest?.address = nil
    #expect(connection.metadata["Request"] == "#0 unknown host")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func satisfy() {
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "192.168.0.2", port: 45345))
    #expect(throws: Never.self) {
      let satisfied = connection.satisfy(predicate: { $0.state == .establishing })
      #expect(satisfied)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func isFinished() async throws {
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "192.168.0.2", port: 45345))
    #expect(!connection.state.isFinished)

    connection.state = .active
    #expect(!connection.state.isFinished)

    connection.state = .completed
    #expect(connection.state.isFinished)

    connection.state = .failed
    #expect(connection.state.isFinished)

    connection.state = .cancelled
    #expect(connection.state.isFinished)
  }
}
