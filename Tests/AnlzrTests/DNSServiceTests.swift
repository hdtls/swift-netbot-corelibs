//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2023 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Atomics
import Logging
import NIOCore
import Testing

@testable import Anlzr

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@Suite struct DNSServiceTests {

  private let application = Analyzer(
    group: MultiThreadedEventLoopGroup.singleton,
    logger: .init(label: "")
  )

  @Test func dnsService() async throws {
    final class DNSResolver: Anlzr.Resolver, Service, Sendable {
      let eventLoop: any EventLoop
      init(eventLoop: any EventLoop) {
        self.eventLoop = eventLoop
      }

      func initiateAQuery(host: String, port: Int)
        -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
      {
        eventLoop.makeSucceededFuture([try! SocketAddress(ipAddress: "127.0.0.1", port: 0)])
      }

      func initiateAAAAQuery(host: String, port: Int)
        -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
      {
        eventLoop.makeSucceededFuture([try! SocketAddress(ipAddress: "::1", port: 0)])
      }

      func cancelQueries() {
      }
    }

    let application = Analyzer(
      group: MultiThreadedEventLoopGroup.singleton,
      logger: .init(label: "")
    )

    #expect(application.services.dns.service as? DefaultResolver != nil)
    var a = try await application.services.dns.service.initiateAQuery(host: "", port: 0).get()
    #expect(a == [])

    var aaaa = try await application.services.dns.service.initiateAAAAQuery(host: "", port: 0).get()
    #expect(aaaa == [])

    let resolver = DNSResolver(eventLoop: MultiThreadedEventLoopGroup.singleton.any())
    application.services.dns.use { _ in resolver }
    #expect(application.services.dns.service as! DNSResolver === resolver)

    a = try await application.services.dns.service.initiateAQuery(host: "", port: 0).get()
    #expect(a == [try! SocketAddress(ipAddress: "127.0.0.1", port: 0)])

    aaaa = try await application.services.dns.service.initiateAAAAQuery(host: "", port: 0).get()
    #expect(aaaa == [try! SocketAddress(ipAddress: "::1", port: 0)])
  }
}
