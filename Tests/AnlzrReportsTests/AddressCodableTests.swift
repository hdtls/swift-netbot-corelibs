//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import NEAddressProcessing
import Testing

@testable import AnlzrReports

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct AddressCodableTests {

  @available(SwiftStdlib 5.9, *)
  @Test func hostPortAddress() async throws {
    let hostPort = Address.hostPort(host: "127.0.0.1", port: 1111)

    let data = try JSONEncoder().encode(hostPort)
    let jsonString = String(data: data, encoding: .utf8)
    #expect(jsonString == "\"[hostPort] 127.0.0.1:1111\"")

    #expect(throws: Never.self) {
      let result = try JSONDecoder().decode(Address.self, from: data)
      #expect(result == hostPort)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func ipv6HostPortAddress() async throws {
    let hostPort = Address.hostPort(host: "::1", port: 1111)

    let data = try JSONEncoder().encode(hostPort)
    let jsonString = String(data: data, encoding: .utf8)
    #expect(jsonString == "\"[hostPort] ::1:1111\"")

    #expect(throws: Never.self) {
      let result = try JSONDecoder().decode(Address.self, from: data)
      #expect(result == hostPort)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func unixPathAddress() async throws {
    let unix = Address.unix(path: "/var/run/tmp.socks")

    let data = try JSONEncoder().encode(unix)
    let jsonString = String(data: data, encoding: .utf8)
    #expect(jsonString == "\"[unix] \\/var\\/run\\/tmp.socks\"")

    #expect(throws: Never.self) {
      let result = try JSONDecoder().decode(Address.self, from: data)
      #expect(result == unix)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func urlAddress() async throws {
    let url = Address.url(URL(string: "https://example.com")!)

    let data = try JSONEncoder().encode(url)
    let jsonString = String(data: data, encoding: .utf8)
    #expect(jsonString == "\"[url] https:\\/\\/example.com\"")

    #expect(throws: Never.self) {
      let result = try JSONDecoder().decode(Address.self, from: data)
      #expect(result == url)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func decodeURLAddressFromInvalidData() async throws {
    let data = "\"[url] https://[fe80::3221:5634:6544]invalid:433/\"".data(using: .utf8)!
    #expect(throws: DecodingError.self) {
      _ = try JSONDecoder().decode(Address.self, from: data)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func decodeAddressFromUnknown() async throws {
    let data = "\"[unknown] 127.0.0.1:80\"".data(using: .utf8)!
    #expect(throws: DecodingError.self) {
      _ = try JSONDecoder().decode(Address.self, from: data)
    }
  }
}
