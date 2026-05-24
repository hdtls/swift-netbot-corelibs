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

import HTTPTypes
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

#if !canImport(Network)
  import NIOPosix
#endif

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  import SynchronizationExtras
#else
  import Synchronization
#endif

@Suite struct ConnectionTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  struct MockProcessReporting: ProcessReporting {
    let processReportResult: Result<ProcessReport, any Error>

    func processInfo(connection: NetbotLiteData.Connection) async throws
      -> NetbotLiteData.ProcessReport
    {
      try processReportResult.get()
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  struct MockDNSResolver: NetbotLite.Resolver {
    let eventLoop: any EventLoop
    let v4Result: Result<[Address], any Error>
    let v6Result: Result<[Address], any Error>

    func initiateAQuery(host: String, port: Int) -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
    {
      eventLoop.makeCompletedFuture {
        try v4Result.get().map { try $0.asAddress() }
      }
    }

    func initiateAAAAQuery(host: String, port: Int)
      -> NIOCore.EventLoopFuture<[NIOCore.SocketAddress]>
    {
      eventLoop.makeCompletedFuture {
        try v6Result.get().map { try $0.asAddress() }
      }
    }

    func cancelQueries() {
    }
  }

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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func processInfoLookup() async throws {
    let connection = Connection()
    connection.establishmentReport = .init()
    try await connection
      .processInfoLookup(
        logger: .init(label: "test"),
        proc: MockProcessReporting(processReportResult: .success(.init()))
      )
    #expect(connection.processReport == nil)

    connection.$establishmentReport.withLock {
      $0?.sourceEndpoint = .hostPort(host: "127.0.0.1", port: 6232)
    }
    try await connection
      .processInfoLookup(
        logger: .init(label: "test"),
        proc: MockProcessReporting(processReportResult: .success(.init()))
      )
    #expect(connection.processReport != nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func dnsLookupIfAddressIsNil() async throws {
    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()

    let connection = Connection()
    #expect(connection.dnsResolutionReport == nil)

    try await connection
      .dnsLookup(
        logger: .init(label: "dns"),
        resolver: DefaultResolver(eventLoop: eventLoop),
        on: eventLoop
      )
    let report = try #require(connection.dnsResolutionReport)
    #expect(report.resolutions.isEmpty)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    Request(address: .url(URL(string: "test.com:443")!)),
    Request(address: .unix(path: "/var/run/tmp.sock")),
  ])
  func dnsLookupIfAddressIsUnixPathOrURL(originalRequest: Request) async throws {
    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()

    let connection = Connection()
    connection.originalRequest = originalRequest
    #expect(connection.dnsResolutionReport == nil)

    try await connection
      .dnsLookup(
        logger: .init(label: "dns"),
        resolver: DefaultResolver(eventLoop: eventLoop),
        on: eventLoop
      )
    let report = try #require(connection.dnsResolutionReport)
    #expect(report.resolutions.isEmpty)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: [
    Request(address: .hostPort(host: "123.123.123.123", port: 0)),
    Request(address: .hostPort(host: "::1", port: 0)),
  ])
  func dnsLookupIfAddressIsIPv4OrIPv6(originalRequest: Request) async throws {
    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()

    let connection = Connection()
    connection.originalRequest = originalRequest
    #expect(connection.dnsResolutionReport == nil)

    try await connection
      .dnsLookup(
        logger: .init(label: "dns"),
        resolver: DefaultResolver(eventLoop: eventLoop),
        on: eventLoop
      )
    let report = try #require(connection.dnsResolutionReport)
    #expect(report.resolutions.count == 1)
    let resolution = try #require(report.resolutions.first)
    #expect(resolution.dnsProtocol == .unknown)
    #expect(resolution.source == .cache)
    #expect(resolution.endpointCount == 1)
    #expect(resolution.endpoints.first == originalRequest.address)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func dnsLookupIfAddressIsHostname() async throws {
    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "localhost", port: 0))
    #expect(connection.dnsResolutionReport == nil)

    let dnsResolver = MockDNSResolver(
      eventLoop: eventLoop,
      v4Result: .success([Address.hostPort(host: "127.0.0.1", port: 0)]),
      v6Result: .success([Address.hostPort(host: "::1", port: 0)])
    )
    try await connection
      .dnsLookup(
        logger: .init(label: "dns"),
        resolver: dnsResolver,
        on: eventLoop
      )
    let report = try #require(connection.dnsResolutionReport)
    #expect(!report.resolutions.isEmpty)
    #expect(report.resolutions.count == 2)

    for resolution in report.resolutions {
      #expect(resolution.dnsProtocol == .udp)
      #expect(resolution.source == .query)
      #expect(resolution.endpointCount == 1)
      #expect(throws: Never.self) {
        let v4Result = try dnsResolver.v4Result.get()
        let v6Result = try dnsResolver.v6Result.get()
        #expect(resolution.endpoints == v4Result || resolution.endpoints == v6Result)
      }
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func dnsLookupIfV4ResultIsEmptyAndV6Failed() async {
    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "localhost", port: 0))
    #expect(connection.dnsResolutionReport == nil)

    let dnsResolver = MockDNSResolver(
      eventLoop: eventLoop,
      v4Result: .success([]),
      v6Result: .failure(CancellationError())
    )

    await #expect(throws: CancellationError.self) {
      try await connection
        .dnsLookup(
          logger: .init(label: "dns"),
          resolver: dnsResolver,
          on: eventLoop
        )
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func dnsLookupIfV4FailedAndV6ResultIsEmpty() async {
    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "localhost", port: 0))
    #expect(connection.dnsResolutionReport == nil)

    let dnsResolver = MockDNSResolver(
      eventLoop: eventLoop,
      v4Result: .failure(CancellationError()),
      v6Result: .success([])
    )

    await #expect(throws: CancellationError.self) {
      try await connection
        .dnsLookup(
          logger: .init(label: "dns"),
          resolver: dnsResolver,
          on: eventLoop
        )
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func dnsLookupIfV4ResultContainsAtLeastOneEndpointButV6Failed() async {
    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "localhost", port: 0))
    #expect(connection.dnsResolutionReport == nil)

    let dnsResolver = MockDNSResolver(
      eventLoop: eventLoop,
      v4Result: .success([.hostPort(host: "127.0.0.1", port: 0)]),
      v6Result: .failure(CancellationError())
    )

    await #expect(throws: Never.self) {
      try await connection
        .dnsLookup(
          logger: .init(label: "dns"),
          resolver: dnsResolver,
          on: eventLoop
        )

      let report = try #require(connection.dnsResolutionReport)
      #expect(report.resolutions.count == 1)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func dnsLookupIfV6ResultContainsAtLeastOneEndpointButV4Failed() async {
    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "localhost", port: 0))
    #expect(connection.dnsResolutionReport == nil)

    let dnsResolver = MockDNSResolver(
      eventLoop: eventLoop,
      v4Result: .failure(CancellationError()),
      v6Result: .success([.hostPort(host: "::1", port: 0)])
    )

    await #expect(throws: Never.self) {
      try await connection
        .dnsLookup(
          logger: .init(label: "dns"),
          resolver: dnsResolver,
          on: eventLoop
        )

      let report = try #require(connection.dnsResolutionReport)
      #expect(report.resolutions.count == 1)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func dnsLookupBothV4AndV6Failed() async {
    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "localhost", port: 0))
    #expect(connection.dnsResolutionReport == nil)

    let dnsResolver = MockDNSResolver(
      eventLoop: eventLoop,
      v4Result: .failure(CancellationError()),
      v6Result: .failure(CancellationError())
    )

    await #expect(throws: CancellationError.self) {
      try await connection
        .dnsLookup(
          logger: .init(label: "dns"),
          resolver: dnsResolver,
          on: eventLoop
        )
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func ruleLookup() async throws {
    struct MockRuleEngine: RulesEngine {
      let forwardingRules: [any NetbotLite.ForwardingRuleConvertible] = []
      let forwardingReport: ForwardingReport

      func setForwardingRules(_ forwardingRules: [any NetbotLite.ForwardingRuleConvertible]) {
      }

      func executeAllRules(connection: NetbotLiteData.Connection) async
        -> NetbotLiteData.ForwardingReport
      {
        forwardingReport
      }
    }

    struct MockForwardingRule: ForwardingRule {
      var forwardProtocol: any NetbotLite.ForwardProtocolConvertible = .direct

      var description: String { "" }

      func predicate(_ connection: NetbotLiteData.Connection) throws -> Bool {
        true
      }
    }

    let connection = Connection()
    connection.establishmentReport = .init()
    #expect(connection.forwardingReport == nil)

    try await connection
      .ruleLookup(
        logger: .init(label: "rule"),
        rulesEngine: MockRuleEngine(forwardingReport: .init(forwardingRule: MockForwardingRule()))
      )

    #expect(connection.forwardingReport != nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func protocolLookupFailedIfDNSLookupFailed() async throws {
    struct MockRuleEngine: RulesEngine {
      let forwardingRules: [any NetbotLite.ForwardingRuleConvertible] = []
      let forwardingReport: ForwardingReport

      func setForwardingRules(_ forwardingRules: [any NetbotLite.ForwardingRuleConvertible]) {
      }

      func executeAllRules(connection: NetbotLiteData.Connection) async
        -> NetbotLiteData.ForwardingReport
      {
        forwardingReport
      }
    }

    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()
    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "test.com", port: 443))
    connection.establishmentReport = .init()

    await #expect(throws: CancellationError.self) {
      try await connection
        .evalProtocolLookup(
          logger: .init(label: "proto"),
          outboundMode: .direct,
          forwardProtocol: .direct,
          proc: MockProcessReporting(processReportResult: .success(.init())),
          resolver: MockDNSResolver(
            eventLoop: eventLoop,
            v4Result: .failure(CancellationError()),
            v6Result: .success([])
          ),
          rules: MockRuleEngine(forwardingReport: .init()),
          on: eventLoop
        )
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func protocolLookupFailedIfProcessInfoLookupFailed() async throws {
    struct MockRuleEngine: RulesEngine {
      let forwardingRules: [any NetbotLite.ForwardingRuleConvertible] = []
      let forwardingReport: ForwardingReport

      func setForwardingRules(_ forwardingRules: [any NetbotLite.ForwardingRuleConvertible]) {
      }

      func executeAllRules(connection: NetbotLiteData.Connection) async
        -> NetbotLiteData.ForwardingReport
      {
        forwardingReport
      }
    }

    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()
    let connection = Connection()
    connection.establishmentReport = .init(
      duration: .zero,
      attemptStartedAfterInterval: 0,
      previousAttemptCount: 0,
      sourceEndpoint: .hostPort(host: "127.0.0.1", port: 58374),
      usedProxy: false,
      proxyEndpoint: nil,
      resolutions: []
    )

    await #expect(throws: CancellationError.self) {
      try await connection
        .evalProtocolLookup(
          logger: .init(label: "proto"),
          outboundMode: .direct,
          forwardProtocol: .direct,
          proc: MockProcessReporting(processReportResult: .failure(CancellationError())),
          resolver: MockDNSResolver(
            eventLoop: eventLoop,
            v4Result: .success([]),
            v6Result: .success([])
          ),
          rules: MockRuleEngine(forwardingReport: .init()),
          on: eventLoop
        )
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func protocolLookupForDirectOutbound() async throws {
    struct MockRuleEngine: RulesEngine {
      let forwardingRules: [any NetbotLite.ForwardingRuleConvertible] = []
      let forwardingReport: ForwardingReport

      func setForwardingRules(_ forwardingRules: [any NetbotLite.ForwardingRuleConvertible]) {
      }

      func executeAllRules(connection: NetbotLiteData.Connection) async
        -> NetbotLiteData.ForwardingReport
      {
        forwardingReport
      }
    }

    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()
    let connection = Connection()
    connection.establishmentReport = .init()

    try await connection
      .evalProtocolLookup(
        logger: .init(label: "proto"),
        outboundMode: .direct,
        forwardProtocol: .direct,
        proc: MockProcessReporting(processReportResult: .success(.init())),
        resolver: MockDNSResolver(
          eventLoop: eventLoop,
          v4Result: .success([]),
          v6Result: .success([])
        ),
        rules: MockRuleEngine(forwardingReport: .init()),
        on: eventLoop
      )

    let report = try #require(connection.forwardingReport)
    #expect(report._forwardProtocol != nil)
    #expect(report._forwardProtocol is ForwardProtocolDirect)
    #expect(report._forwardingRule == nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func protocolLookupForGlobalProxyOutbound() async throws {
    struct MockRuleEngine: RulesEngine {
      let forwardingRules: [any NetbotLite.ForwardingRuleConvertible] = []
      let forwardingReport: ForwardingReport

      func setForwardingRules(_ forwardingRules: [any NetbotLite.ForwardingRuleConvertible]) {
      }

      func executeAllRules(connection: NetbotLiteData.Connection) async
        -> NetbotLiteData.ForwardingReport
      {
        forwardingReport
      }
    }

    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()
    let connection = Connection()
    connection.establishmentReport = .init()

    try await connection
      .evalProtocolLookup(
        logger: .init(label: "proto"),
        outboundMode: .globalProxy,
        forwardProtocol: .rejectTinyGIF,
        proc: MockProcessReporting(processReportResult: .success(.init())),
        resolver: MockDNSResolver(
          eventLoop: eventLoop,
          v4Result: .success([]),
          v6Result: .success([])
        ),
        rules: MockRuleEngine(forwardingReport: .init()),
        on: eventLoop
      )

    let report = try #require(connection.forwardingReport)
    #expect(report._forwardProtocol is ForwardProtocolRejectTinyGIF)
    #expect(report._forwardingRule == nil)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func protocolLookupForRuleBasedOutbound() async throws {
    struct MockRuleEngine: RulesEngine {
      let forwardingRules: [any NetbotLite.ForwardingRuleConvertible] = []
      let forwardingReport: ForwardingReport

      func setForwardingRules(_ forwardingRules: [any NetbotLite.ForwardingRuleConvertible]) {
      }

      func executeAllRules(connection: NetbotLiteData.Connection) async
        -> NetbotLiteData.ForwardingReport
      {
        forwardingReport
      }
    }

    struct MockForwardingRule: ForwardingRule {
      var forwardProtocol: any NetbotLite.ForwardProtocolConvertible = .rejectTinyGIF

      var description: String { "DOMAIN-SUFFIX,test.com,REJECT-TINYGIF" }

      func predicate(_ connection: NetbotLiteData.Connection) throws -> Bool {
        true
      }
    }

    let group: any EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let eventLoop = group.next()
    let connection = Connection()
    connection.establishmentReport = .init()

    try await connection
      .evalProtocolLookup(
        logger: .init(label: "proto"),
        outboundMode: .ruleBased,
        forwardProtocol: .direct,
        proc: MockProcessReporting(processReportResult: .success(.init())),
        resolver: MockDNSResolver(
          eventLoop: eventLoop,
          v4Result: .success([]),
          v6Result: .success([])
        ),
        rules: MockRuleEngine(forwardingReport: .init(forwardingRule: MockForwardingRule())),
        on: eventLoop
      )

    let report = try #require(connection.forwardingReport)
    #expect(report._forwardProtocol != nil)
    #expect(report._forwardProtocol is ForwardProtocolRejectTinyGIF)
    #expect(report._forwardingRule != nil)
    #expect(report._forwardingRule is MockForwardingRule)
  }
}
