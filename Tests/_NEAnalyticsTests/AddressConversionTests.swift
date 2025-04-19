//
// See LICENSE.txt for license information
//

import NEAddressProcessing
import NIOCore
import Testing

@testable import _NEAnalytics

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

struct AddressConversionTests {

  @Test func convertIPv4Address() async throws {
    let expected = try! SocketAddress(ipAddress: "127.0.0.1", port: 0)
    #expect(try! Address.hostPort(host: "127.0.0.1", port: 0).address == expected)
  }

  @Test func converIPv6Address() async throws {
    let expected = try! SocketAddress(ipAddress: "::1", port: 0)
    #expect(try! Address.hostPort(host: "::1", port: 0).address == expected)
  }

  @Test func convertUnixSocketPath() async throws {
    let expected = try! SocketAddress(unixDomainSocketPath: "/var/run/tmp.sock")
    #expect(try! Address.unix(path: "/var/run/tmp.sock").address == expected)
  }

  @Test func convertURL() async throws {
    let expected = try! SocketAddress(ipAddress: "127.0.0.1", port: 0)
    #expect(try! Address.url(URL(string: "http://127.0.0.1:0")!).address == expected)
  }
}
