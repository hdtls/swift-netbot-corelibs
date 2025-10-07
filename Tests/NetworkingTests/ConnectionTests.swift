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

import AnlzrReports
import Logging
import NEAddressProcessing
import Testing

@testable import Networking

@Suite struct ConnectionTests {

  @Test func metadata() async throws {
    var connection = Connection(taskIdentifier: 0)
    connection.originalRequest = .init(address: .hostPort(host: "192.168.0.2", port: 45345))
    #expect(connection.metadata["Request"] == "#0 192.168.0.2:45345")

    connection = Connection(taskIdentifier: 0)
    connection.originalRequest = .init(address: .unix(path: "/var/tmp/sock.sock"))

    connection.originalRequest?.address = nil
    #expect(connection.metadata["Request"] == "#0 unknown host")
  }

  @Test func satisfy() {
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "192.168.0.2", port: 45345))
    #expect(throws: Never.self) {
      let satisfied = connection.satisfy(predicate: { $0.state == .establishing })
      #expect(satisfied)
    }
  }

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
