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
import Testing

@testable import NetbotDNS

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct AddressConversionTests {

  @available(SwiftStdlib 6.0, *)
  @Test func convertSocketAddressToAddress() throws {
    #expect(throws: Never.self) {
      let sa = try SocketAddress(ipAddress: "::1", port: 0).asAddress()
      #expect(sa == .hostPort(host: "::1", port: 0))
    }

    #expect(throws: Never.self) {
      let sa = try SocketAddress(ipAddress: "127.0.0.1", port: 0).asAddress()
      #expect(sa == .hostPort(host: "127.0.0.1", port: 0))
    }

    #expect(throws: Never.self) {
      let sa = try SocketAddress(unixDomainSocketPath: "/var/tmp/test.sock").asAddress()
      #expect(sa == .unix(path: "/var/tmp/test.sock"))
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func convertAddressToSocketAddress() async throws {
    #expect(throws: SocketAddressError.unsupported) {
      _ = try Address.hostPort(host: "swift.org", port: 443).asAddress()
    }

    #expect(throws: Never.self) {
      let sa = try Address.hostPort(host: "127.0.0.1", port: 0).asAddress()
      let a = try SocketAddress(ipAddress: "127.0.0.1", port: 0)
      #expect(sa == a)
    }

    #expect(throws: Never.self) {
      let sa = try Address.hostPort(host: "::1", port: 0).asAddress()
      let a = try SocketAddress(ipAddress: "::1", port: 0)
      #expect(sa == a)
    }

    #expect(throws: Never.self) {
      let sa = try Address.unix(path: "/var/tmp/test.sock").asAddress()
      let a = try SocketAddress(unixDomainSocketPath: "/var/tmp/test.sock")
      #expect(sa == a)
    }

    #expect(throws: SocketAddressError.unsupported) {
      _ = try Address.url(URL(string: "https://swift.org")!).asAddress()
    }
  }
}
