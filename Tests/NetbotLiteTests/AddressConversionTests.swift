// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import NEAddressProcessing
import NIOCore
import Testing

@testable import NetbotLite

#if canImport(Network)
  import Network
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct AddressConversionTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func convertAddressToSocketAddress() async throws {
    #expect(throws: Never.self) {
      let sa = try Address.hostPort(host: "::1", port: 0).asAddress()
      let a = try SocketAddress(ipAddress: "::1", port: 0)
      #expect(sa == a)
    }

    #expect(throws: Never.self) {
      let sa = try Address.hostPort(host: "127.0.0.1", port: 0).asAddress()
      let a = try SocketAddress(ipAddress: "127.0.0.1", port: 0)
      #expect(sa == a)
    }

    #expect(throws: Never.self) {
      let sa = try Address.unix(path: "/var/tmp/test.sock").asAddress()
      let a = try SocketAddress(unixDomainSocketPath: "/var/tmp/test.sock")
      #expect(sa == a)
    }

    #expect(throws: AnalyzeError.operationUnsupported) {
      _ = try Address.url(URL(string: "https://swift.org")!).asAddress()
    }
  }

  #if canImport(Network)
    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func convertNWEndpointToAddress() {
      #expect(throws: Never.self) {
        let sa = try NWEndpoint.hostPort(host: "::1", port: 0).asAddress()
        #expect(sa == .hostPort(host: "::1", port: 0))
      }

      #expect(throws: Never.self) {
        let sa = try NWEndpoint.hostPort(host: "127.0.0.1", port: 0).asAddress()
        #expect(sa == .hostPort(host: "127.0.0.1", port: 0))
      }

      #expect(throws: Never.self) {
        let sa = try NWEndpoint.hostPort(host: "swift.org", port: 443).asAddress()
        #expect(sa == .hostPort(host: "swift.org", port: 443))
      }

      #expect(throws: AnalyzeError.operationUnsupported) {
        _ = try NWEndpoint.service(
          name: "someservice", type: "service type", domain: "service domain", interface: nil
        ).asAddress()
      }

      #expect(throws: Never.self) {
        let sa = try NWEndpoint.unix(path: "/var/tmp/test.sock").asAddress()
        #expect(sa == .unix(path: "/var/tmp/test.sock"))
      }

      #expect(throws: Never.self) {
        let sa = try NWEndpoint.url(URL(string: "https://swift.org")!).asAddress()
        #expect(sa == .url(URL(string: "https://swift.org")!))
      }
    }

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.5, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
    @Test func convertAddressToNWEndpoint() async throws {
      #expect(throws: Never.self) {
        let sa = try Address.hostPort(host: "::1", port: 0).asEndpoint()
        #expect(sa == .hostPort(host: "::1", port: 0))
      }

      #expect(throws: Never.self) {
        let sa = try Address.hostPort(host: "127.0.0.1", port: 0).asEndpoint()
        #expect(sa == .hostPort(host: "127.0.0.1", port: 0))
      }

      #expect(throws: Never.self) {
        let sa = try Address.hostPort(host: "swift.org", port: 443).asEndpoint()
        #expect(sa == .hostPort(host: "swift.org", port: 443))
      }

      #expect(throws: Never.self) {
        let sa = try Address.unix(path: "/var/tmp/test.sock").asEndpoint()
        #expect(sa == .unix(path: "/var/tmp/test.sock"))
      }

      #expect(throws: Never.self) {
        let sa = try Address.url(URL(string: "https://swift.org")!).asEndpoint()
        #expect(sa == .url(URL(string: "https://swift.org")!))
      }
    }
  #endif
}
