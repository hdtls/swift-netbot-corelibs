// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct ConnectionStateTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hashableConformance() async throws {
    let state = Connection.State.establishing

    #expect(state == .establishing)

    let states: Set<Connection.State> = [.establishing, .active, .active]
    #expect(states == [.establishing, .active])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func codableConformance() async throws {
    let state = Connection.State.establishing
    let data = try JSONEncoder().encode(state)
    let encodedJSONString = String(data: data, encoding: .utf8)
    #expect(encodedJSONString == "\"establishing\"")

    let result = try JSONDecoder().decode(Connection.State.self, from: data)
    #expect(result == state)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(
    arguments: zip(
      [Connection.State.establishing, .active, .completed, .failed, .cancelled],
      ["establishing", "active", "completed", "failed", "cancelled"]))
  func rawRepresentableConformance(state: Connection.State, rawValue: String) async throws {
    #expect(state == Connection.State(rawValue: rawValue))
    #expect(state.rawValue == rawValue)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func caseIterableConformance() async throws {
    #expect(
      Connection.State.allCases == [.establishing, .active, .completed, .failed, .cancelled])
  }
}
