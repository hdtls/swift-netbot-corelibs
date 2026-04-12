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

import Logging
import NEAddressProcessing
import NIOCore
import NetbotLiteData
import Testing

@testable import NetbotLite

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@Suite struct RulesEngineTests {

  @Test func setForwardingRules() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    #expect(service.forwardingRules.isEmpty)
    #expect(service.cache.isEmpty)

    service.setForwardingRules([_FinalForwardingRule()])
    #expect(service.forwardingRules.count == 1)
    #expect(service.cache.isEmpty)

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))
    let _ = await service.executeAllRules(connection: connection)
    #expect(service.forwardingRules.count == 1)
    #expect(!service.cache.isEmpty)

    service.setForwardingRules([_FinalForwardingRule()])
    #expect(service.forwardingRules.count == 1)
    // Set new rules should invalidate all cache.
    #expect(service.cache.isEmpty)
  }

  @Test func ruleLookupWithoutCache() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([_FinalForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))
    let result = await service.executeAllRules(connection: connection)
    #expect(result._forwardingRule as? _FinalForwardingRule != nil)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }

  @Test func ruleLookupWithCache() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([_FinalForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))
    // We need cache lookup for first request.
    let _ = await service.executeAllRules(connection: connection)

    // The seconds lookup should use cache directly.
    let result = await service.executeAllRules(connection: connection)

    #expect(result._forwardingRule as? _FinalForwardingRule != nil)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }

  @Test func ruleLookupForConnectionThatOriginalRequestIsNil() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([_FinalForwardingRule()])

    let connection = Connection()
    #expect(connection.originalRequest == nil)
    let result = await service.executeAllRules(connection: connection)

    #expect(result._forwardingRule as? _FinalForwardingRule != nil)
    #expect(result.duration == .zero)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }

  @Test func inFlightTaskWorks() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([_FinalForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))
    async let r1 = await service.executeAllRules(connection: connection)
    async let r2 = await service.executeAllRules(connection: connection)

    let _ = await [r1, r2]
  }

  @Test func ruleLookupFallbackWorks() async throws {
    struct MockForwardingRule: ForwardingRule, ForwardingRuleConvertible {

      var forwardProtocol: any ForwardProtocolConvertible { .direct }

      var description: String { "DOMAIN" }

      func predicate(_ connection: NetbotLiteData.Connection) throws -> Bool {
        false
      }
    }

    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([MockForwardingRule(), MockForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))

    let result = await service.executeAllRules(connection: connection)
    #expect(result._forwardingRule as? FinalForwardingRule != nil)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }

  @Test func replaceBuiltinFinalRuleWithCustomizedFinalRule() async throws {
    struct MockForwardingRule: FinalForwardingRule, ForwardingRuleConvertible {
      var forwardProtocol: any ForwardProtocolConvertible { .reject }
    }

    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([MockForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))

    let result = await service.executeAllRules(connection: connection)
    #expect(result._forwardingRule as? MockForwardingRule != nil)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "REJECT")
  }

  @Test func ruleMatchingFailedWhenRuleLookup() async throws {
    struct MockForwardingRule: ForwardingRule, ForwardingRuleConvertible {

      var forwardProtocol: any ForwardProtocolConvertible { .direct }

      var description: String { "DOMAIN" }

      func predicate(_ connection: NetbotLiteData.Connection) throws -> Bool {
        throw CancellationError()
      }
    }

    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([MockForwardingRule(), _FinalForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))

    let result = await service.executeAllRules(connection: connection)
    #expect(result._forwardingRule as? FinalForwardingRule != nil)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }

  //  @Test func dnsLookupWithNilApplication() async throws {
  //    let service = DefaultRulesEngine(logger: .init(label: ""))
  //
  //    let connection = Connection()
  //    connection.originalRequest = .init(address: .hostPort(host: "example.com", port: 443))
  //    let result = try await service.dnsLookup(connection: connection)
  //    #expect(result.isEmpty)
  //  }
  //
  //  @Test func dnsLookupForConnectionThatHostOfOriginalRequestIsNil() async throws {
  //    let service = DefaultRulesEngine(logger: .init(label: ""))
  //
  //    let connection = Connection()
  //    let result = try await service.dnsLookup(connection: connection)
  //    #expect(result.isEmpty)
  //  }
  //
  //  @Test func dnsLookupForConnectionThatPortOfOriginalRequestIsNil() async throws {
  //    let service = DefaultRulesEngine(logger: .init(label: ""))
  //
  //    let connection = Connection()
  //    connection.originalRequest = .init(address: .url(URL(string: "https://example.com")!))
  //    let result = try await service.dnsLookup(connection: connection)
  //    #expect(result.isEmpty)
  //  }
  //
  //  @Test func dnsLookupForConnectionThatDNSResolutionResultIsEmpty() async throws {
  //    struct MockDNSResolver: Anlzr.Resolver, Sendable {
  //      let eventLoop: any EventLoop
  //
  //      func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[NIOCore.SocketAddress]> {
  //        eventLoop.makeSucceededFuture([])
  //      }
  //
  //      func initiateAAAAQuery(host: String, port: Int)
  //        -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
  //      {
  //        eventLoop.makeSucceededFuture([])
  //      }
  //
  //      func cancelQueries() {
  //
  //      }
  //    }
  //
  //    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
  //    let app = Analyzer(group: group, logger: .init(label: ""))
  //
  //    let resolver = MockDNSResolver(eventLoop: group.any())
  //    app.services.dns.use { _ in resolver }
  //
  //    let connection = Connection()
  //    connection.originalRequest = .init(address: .hostPort(host: "example.com", port: 443))
  //    let result = try await app.services.forwardingRule.service.dnsLookup(connection: connection)
  //    #expect(result.isEmpty)
  //  }
  //
  //  @Test func bothAAndAAAARecordFailedWhenDNSLookup() async throws {
  //    enum MockError: Error, Equatable {
  //      case test1
  //      case test2
  //    }
  //    struct MockDNSResolver: Anlzr.Resolver, Sendable {
  //      let eventLoop: any EventLoop
  //
  //      func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[NIOCore.SocketAddress]> {
  //        eventLoop.makeFailedFuture(MockError.test1)
  //      }
  //
  //      func initiateAAAAQuery(host: String, port: Int)
  //        -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
  //      {
  //        eventLoop.makeFailedFuture(MockError.test2)
  //      }
  //
  //      func cancelQueries() {
  //
  //      }
  //    }
  //
  //    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
  //    let app = Analyzer(group: group, logger: .init(label: ""))
  //
  //    let resolver = MockDNSResolver(eventLoop: group.any())
  //    app.services.dns.use { _ in resolver }
  //
  //    let connection = Connection()
  //    connection.originalRequest = .init(address: .hostPort(host: "example.com", port: 443))
  //
  //    // If both A and AAAA record failed than the last error should be throw.
  //    await #expect(throws: MockError.self) {
  //      try await app.services.forwardingRule.service.dnsLookup(connection: connection)
  //    }
  //  }
  //
  //  @Test func aRecordIsFailedButAAAARecordIsNotEmpty() async throws {
  //    struct MockDNSResolver: Anlzr.Resolver, Sendable {
  //      let eventLoop: any EventLoop
  //
  //      func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[NIOCore.SocketAddress]> {
  //        eventLoop.makeFailedFuture(CancellationError())
  //      }
  //
  //      func initiateAAAAQuery(host: String, port: Int)
  //        -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
  //      {
  //        eventLoop.makeSucceededFuture([try! SocketAddress(ipAddress: "::1", port: 443)])
  //      }
  //
  //      func cancelQueries() {
  //
  //      }
  //    }
  //
  //    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
  //    let app = Analyzer(group: group, logger: .init(label: ""))
  //
  //    let resolver = MockDNSResolver(eventLoop: group.any())
  //    app.services.dns.use { _ in resolver }
  //
  //    let connection = Connection()
  //    connection.originalRequest = .init(address: .hostPort(host: "example.com", port: 443))
  //    let result = try await app.services.forwardingRule.service.dnsLookup(connection: connection)
  //    #expect(!result.isEmpty)
  //    #expect(result.first?.endpointCount == 1)
  //    #expect(result.first?.preferredEndpoint == .hostPort(host: "::1", port: 443))
  //  }
  //
  //  @Test func aaaaRecordIsFailedButARecordIsNotEmpty() async throws {
  //    struct MockDNSResolver: Anlzr.Resolver, Sendable {
  //      let eventLoop: any EventLoop
  //
  //      func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[NIOCore.SocketAddress]> {
  //        eventLoop.makeSucceededFuture([try! SocketAddress(ipAddress: "198.51.100.1", port: 443)])
  //      }
  //
  //      func initiateAAAAQuery(host: String, port: Int)
  //        -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
  //      {
  //        eventLoop.makeFailedFuture(CancellationError())
  //      }
  //
  //      func cancelQueries() {
  //
  //      }
  //    }
  //
  //    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
  //    let app = Analyzer(group: group, logger: .init(label: ""))
  //
  //    let resolver = MockDNSResolver(eventLoop: group.any())
  //    app.services.dns.use { _ in resolver }
  //
  //    let connection = Connection()
  //    connection.originalRequest = .init(address: .hostPort(host: "example.com", port: 443))
  //    let result = try await app.services.forwardingRule.service.dnsLookup(connection: connection)
  //    #expect(!result.isEmpty)
  //    #expect(result.first?.endpointCount == 1)
  //    #expect(result.first?.preferredEndpoint == .hostPort(host: "198.51.100.1", port: 443))
  //  }
  //
  //  @Test func aRecordIsFailedAndAAAARecordIsEmpty() async throws {
  //    enum MockError: Error, Equatable {
  //      case cancelled
  //    }
  //    struct MockDNSResolver: Anlzr.Resolver, Sendable {
  //      let eventLoop: any EventLoop
  //
  //      func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[NIOCore.SocketAddress]> {
  //        eventLoop.makeFailedFuture(MockError.cancelled)
  //      }
  //
  //      func initiateAAAAQuery(host: String, port: Int)
  //        -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
  //      {
  //        eventLoop.makeSucceededFuture([])
  //      }
  //
  //      func cancelQueries() {
  //
  //      }
  //    }
  //
  //    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
  //    let app = Analyzer(group: group, logger: .init(label: ""))
  //
  //    let resolver = MockDNSResolver(eventLoop: group.any())
  //    app.services.dns.use { _ in resolver }
  //
  //    let connection = Connection()
  //    connection.originalRequest = .init(address: .hostPort(host: "example.com", port: 443))
  //
  //    await #expect(throws: MockError.self) {
  //      try await app.services.forwardingRule.service.dnsLookup(connection: connection)
  //    }
  //  }
  //
  //  @Test func aaaaRecordIsFailedAndARecordIsEmpty() async throws {
  //    enum MockError: Error, Equatable {
  //      case cancelled
  //    }
  //    struct MockDNSResolver: Anlzr.Resolver, Sendable {
  //      let eventLoop: any EventLoop
  //
  //      func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[NIOCore.SocketAddress]> {
  //        eventLoop.makeSucceededFuture([])
  //      }
  //
  //      func initiateAAAAQuery(host: String, port: Int)
  //        -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
  //      {
  //        eventLoop.makeFailedFuture(MockError.cancelled)
  //      }
  //
  //      func cancelQueries() {
  //
  //      }
  //    }
  //
  //    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
  //    let app = Analyzer(group: group, logger: .init(label: ""))
  //
  //    let resolver = MockDNSResolver(eventLoop: group.any())
  //    app.services.dns.use { _ in resolver }
  //
  //    let connection = Connection()
  //    connection.originalRequest = .init(address: .hostPort(host: "example.com", port: 443))
  //
  //    await #expect(throws: MockError.self) {
  //      try await app.services.forwardingRule.service.dnsLookup(connection: connection)
  //    }
  //  }
}
