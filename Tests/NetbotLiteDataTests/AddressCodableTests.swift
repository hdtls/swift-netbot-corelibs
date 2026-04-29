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

import NEAddressProcessing
import Testing

@testable import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct AddressCodableTests {

  private var encoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    return encoder
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hostPortNameAddress() async throws {
    let hostPort = Address.hostPort(host: "swift.org", port: 443)

    let data = try encoder.encode(hostPort)
    let jsonString = String(data: data, encoding: .utf8)
    #expect(
      jsonString == "{\"hostPort\":{\"host\":{\"name\":{\"_0\":\"swift.org\"}},\"port\":443}}")

    #expect(throws: Never.self) {
      let result = try JSONDecoder().decode(Address.self, from: data)
      #expect(result == hostPort)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hostPortIPv4Address() async throws {
    let hostPort = Address.hostPort(host: "127.0.0.1", port: 443)

    let data = try encoder.encode(hostPort)
    let jsonString = String(data: data, encoding: .utf8)
    #expect(
      jsonString == "{\"hostPort\":{\"host\":{\"ipv4\":{\"_0\":\"127.0.0.1\"}},\"port\":443}}")

    #expect(throws: Never.self) {
      let result = try JSONDecoder().decode(Address.self, from: data)
      #expect(result == hostPort)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func hostPortIPv6Address() async throws {
    let hostPort = Address.hostPort(host: "::1", port: 443)

    let data = try encoder.encode(hostPort)
    let jsonString = String(data: data, encoding: .utf8)
    #expect(jsonString == "{\"hostPort\":{\"host\":{\"ipv6\":{\"_0\":\"::1\"}},\"port\":443}}")

    #expect(throws: Never.self) {
      let result = try JSONDecoder().decode(Address.self, from: data)
      #expect(result == hostPort)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func unixPathAddress() async throws {
    let unix = Address.unix(path: "/var/run/tmp.sock")

    let data = try encoder.encode(unix)
    let jsonString = String(data: data, encoding: .utf8)
    #expect(jsonString == "{\"unix\":{\"path\":\"\\/var\\/run\\/tmp.sock\"}}")

    #expect(throws: Never.self) {
      let result = try JSONDecoder().decode(Address.self, from: data)
      #expect(result == unix)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func urlAddress() async throws {
    let url = Address.url(URL(string: "https://example.com")!)

    let data = try encoder.encode(url)
    let jsonString = String(data: data, encoding: .utf8)
    #expect(jsonString == "{\"url\":{\"_0\":\"https:\\/\\/example.com\"}}")

    #expect(throws: Never.self) {
      let result = try JSONDecoder().decode(Address.self, from: data)
      #expect(result == url)
    }
  }
}
