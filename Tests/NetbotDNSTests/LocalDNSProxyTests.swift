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
import NIOEmbedded
import NIOPosix
import NetbotLite
import NetbotLiteData
import NetbotProfile
import Testing

@testable import NetbotDNS

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  import Atomics
  import NIOConcurrencyHelpers

  typealias Atomic = ManagedAtomic
#else
  import Synchronization
#endif

@Suite(.tags(.dns))
struct LocalDNSProxyTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  final class MockDNSServer: @unchecked Sendable {
    let queryCalls: Atomic<Int> = .init(0)
    let response: [any ResourceRecord]
    let parser = NLDNSParser()
    private var channel: LocalDNSProxy.AsyncChannel!

    init(response: [any ResourceRecord]) {
      self.response = response
    }

    func start() async throws -> SocketAddress? {
      channel = try await DatagramBootstrap(group: .singletonMultiThreadedEventLoopGroup)
        .bind(to: .init(ipAddress: "127.0.0.1", port: 0)) { channel in
          channel.eventLoop.makeCompletedFuture {
            try LocalDNSProxy.AsyncChannel(wrappingChannelSynchronously: channel)
          }
        }

      Task {
        try? await channel.executeThenClose { inbound, outbound in
          for try await frame in inbound {
            // Always response privoded records.
            queryCalls.wrappingAdd(1, ordering: .relaxed)
            let message = try parser.parse(frame.data)

            let response = Message(
              headerFields: .init(
                transactionID: message.headerFields.transactionID,
                flags: .init(rawValue: 0x8100),
                qestionCount: 1,
                answerCount: UInt16(response.count),
                authorityCount: 0,
                additionCount: 0
              ),
              questions: message.questions,
              answerRRs: response,
              authorityRRs: [],
              additionalRRs: []
            )
            let data = try response.serializedBytes
            let envelop = AddressedEnvelope(
              remoteAddress: frame.remoteAddress, data: ByteBuffer(bytes: data)
            )
            try await outbound.write(envelop)
          }
        }
      }
      return channel.channel.localAddress
    }

    func close(promise: EventLoopPromise<Void>?) {
      channel.channel.close(promise: promise)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func queryA() async throws {
    let server = MockDNSServer(
      response: [
        ARecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(4),
          data: .init("123.123.123.123")!)
      ]
    )
    let address = try #require(await server.start())

    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.queryA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [ARecord])

      _ = try await p.queryA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [ARecord])
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func handleExpiredARecord() async throws {
    let server = MockDNSServer(
      response: [
        ARecord(
          domainName: "example.com", ttl: 1, dataLength: .determined(4),
          data: .init("123.123.123.123")!)
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.queryA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)

      // Wait for expiration.
      try await Task.sleep(for: .seconds(1))

      _ = try await p.queryA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func queryAAAA() async throws {
    let server = MockDNSServer(
      response: [
        AAAARecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(16), data: .init("::1")!)
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.queryAAAA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [AAAARecord])

      _ = try await p.queryAAAA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [AAAARecord])
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func handleExpiredAAAARecord() async throws {
    let server = MockDNSServer(
      response: [AAAARecord(domainName: "example.com", ttl: 1, data: .init("::1")!)]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.queryAAAA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)

      // Wait for expiration.
      try await Task.sleep(for: .seconds(1))

      _ = try await p.queryAAAA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func queryNS() async throws {
    let server = MockDNSServer(
      response: [
        NSRecord(domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.queryNS(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [NSRecord])

      _ = try await p.queryNS(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [NSRecord])
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func queryCNAME() async throws {
    let server = MockDNSServer(
      response: [
        CNAMERecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.queryCNAME(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [CNAMERecord])

      _ = try await p.queryCNAME(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [CNAMERecord])
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func querySOA() async throws {
    let server = MockDNSServer(
      response: [
        SOARecord(
          domainName: "example.com", ttl: 300,
          dataLength: .determined(35),
          data: .init(
            primaryNameServer: "primary.example.com", responsibleMailbox: "mx.example.com",
            serialNumber: 0, refreshInterval: 0, retryInterval: 0, expirationTime: 0, ttl: 300))
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.querySOA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [SOARecord])

      _ = try await p.querySOA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [SOARecord])
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func queryPTR() async throws {
    let server = MockDNSServer(
      response: [
        PTRRecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.queryPTR(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [PTRRecord])

      _ = try await p.queryPTR(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [PTRRecord])
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func queryMX() async throws {
    let server = MockDNSServer(
      response: [
        MXRecord(
          domainName: "example.com",
          ttl: 300,
          dataLength: .determined(10),
          data: .init(
            preference: 10,
            exchange: "1.exp.com"
          )
        )
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.queryMX(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [MXRecord])

      _ = try await p.queryMX(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [MXRecord])
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func queryTXT() async throws {
    let server = MockDNSServer(
      response: [
        TXTRecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(10), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.queryTXT(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [TXTRecord])

      _ = try await p.queryTXT(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [TXTRecord])
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func querySRV() async throws {
    let server = MockDNSServer(
      response: [
        SRVRecord(
          domainName: "example.com", ttl: 300,
          dataLength: .determined(14),
          data: .init(priority: 0, weight: 0, port: 33, hostname: "1.exp.com"))
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [try address.asAddress()],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    await #expect(throws: Never.self) {
      let result = try await p.querySRV(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [SRVRecord])

      _ = try await p.querySRV(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [SRVRecord])
    }

    server.close(promise: nil)
    try await p.shutdownGracefully()
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func rejectResponseMessage() async throws {
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )

    let message = Message(
      response: true,
      questions: [.init(domainName: "swift.org", queryType: .a)]
    )

    await #expect(throws: Never.self) {
      let result = try await p.query(msg: message)
      #expect(result.headerFields.flags.responseCode == .formErr)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func handleOnlyQueryOperations() async throws {
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )

    let message = Message(
      response: false,
      operationCode: .notify,
      questions: [.init(domainName: "swift.org", queryType: .a)]
    )

    await #expect(throws: Never.self) {
      let result = try await p.query(msg: message)
      #expect(result.headerFields.flags.responseCode == .notImp)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func standardServerOnlyHandleMessageWithExactlyOneQuestion() async throws {
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )

    let message = Message(
      response: false,
      operationCode: .query,
      questions: [
        .init(domainName: "swift.org", queryType: .a),
        .init(domainName: "swift.org", queryType: .aaaa),
      ]
    )

    await #expect(throws: Never.self) {
      let result = try await p.query(msg: message)
      #expect(result.headerFields.flags.responseCode == .formErr)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func aAddressMapping() async throws {
    let mapping = ProtocolDNS.Mapping(
      strategy: .mapping, domainName: "localhost", value: "127.0.0.1", note: "")
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [],
        mappings: [mapping],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    let expected = Message(
      headerFields: .init(
        transactionID: 0x1165,
        flags: .init(
          response: false,
          opcode: .query,
          authoritative: false,
          truncated: false,
          recursionDesired: false,
          recursionAvailable: false,
          authenticatedData: false,
          checkingDisabled: true,
          responseCode: .noError
        ),
        qestionCount: 1,
        answerCount: 1,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [.init(domainName: "localhost", queryType: .a)],
      answerRRs: [
        ARecord(
          domainName: "localhost", ttl: 0, dataLength: .determined(4),
          data: IPv4Address(mapping.value)!)
      ],
      authorityRRs: [],
      additionalRRs: []
    )
    let response = try await p.query(
      msg: .init(
        transactionID: 0x1165,
        response: false,
        questions: expected.questions
      )
    )

    #expect(response.headerFields.qestionCount == expected.headerFields.qestionCount)
    #expect(response.headerFields.answerCount == expected.headerFields.answerCount)
    #expect(response.questions == expected.questions)
    #expect(response.answerRRs as! [ARecord] == expected.answerRRs as! [ARecord])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func aaaaAddressMapping() async throws {
    let mapping = ProtocolDNS.Mapping(
      strategy: .mapping, domainName: "localhost", value: "::1", note: "")
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [],
        mappings: [mapping],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    let expected = Message(
      headerFields: .init(
        transactionID: 0x1165,
        flags: .init(
          response: false,
          opcode: .query,
          authoritative: false,
          truncated: false,
          recursionDesired: false,
          recursionAvailable: false,
          authenticatedData: false,
          checkingDisabled: true,
          responseCode: .noError
        ),
        qestionCount: 1,
        answerCount: 1,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [.init(domainName: "localhost", queryType: .aaaa)],
      answerRRs: [
        AAAARecord(
          domainName: "localhost", ttl: 0, dataLength: .determined(16),
          data: IPv6Address(mapping.value)!)
      ],
      authorityRRs: [],
      additionalRRs: []
    )
    let response = try await p.query(
      msg: .init(
        transactionID: 0x1165,
        response: false,
        questions: expected.questions
      )
    )

    #expect(response.headerFields.qestionCount == expected.headerFields.qestionCount)
    #expect(response.headerFields.answerCount == expected.headerFields.answerCount)
    #expect(response.questions == expected.questions)
    #expect(response.answerRRs as! [AAAARecord] == expected.answerRRs as! [AAAARecord])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func cnameMapping() async throws {
    let mapping = ProtocolDNS.Mapping(
      strategy: .cname, domainName: "example.com", value: "test.com", note: "")
    let p = LocalDNSProxy(
      options: .init(
        group: .shared,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [],
        mappings: [mapping],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await p.run()

    let expected = Message(
      headerFields: .init(
        transactionID: 0x1165,
        flags: .init(
          response: false,
          opcode: .query,
          authoritative: false,
          truncated: false,
          recursionDesired: false,
          recursionAvailable: false,
          authenticatedData: false,
          checkingDisabled: true,
          responseCode: .noError
        ),
        qestionCount: 1,
        answerCount: 1,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [.init(domainName: "example.com", queryType: .aaaa)],
      answerRRs: [CNAMERecord(domainName: "example.com", ttl: 0, data: "test.com")],
      authorityRRs: [],
      additionalRRs: []
    )
    let response = try await p.query(
      msg: .init(
        transactionID: 0x1165,
        response: false,
        questions: expected.questions
      )
    )

    #expect(response.headerFields.qestionCount == expected.headerFields.qestionCount)
    #expect(response.headerFields.answerCount == expected.headerFields.answerCount)
    #expect(response.questions == expected.questions)
    #expect(response.answerRRs as! [CNAMERecord] == expected.answerRRs as! [CNAMERecord])
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func dnsServerAddressMapping() async throws {
    //    let server = MockDNSServer(
    //      response: [
    //        PTRRecord(
    //          domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
    //      ]
    //    )
    //    let address = try #require(await server.start())
    //    let p = LocalDNSProxy(
    //      options: .init(
    //        group: .shared,
    //        bindAddress: IPv4Address("198.18.0.2")!,
    //        additionalServers: [Address.hostPort(host: "8.8.8.8", port: 53)],
    //        availableIPPool: AvailableIPPool(
    //          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
    //        ),
    //        dnsMappings: [
    //          .init(strategy: .dns, domainName: "example.com", value: "\(address)", note: "")
    //        ]
    //      )
    //    )
    //    try await p.run()
    //
    //    await #expect(throws: Never.self) {
    //      let result = try await p.queryPTR(name: "example.com")
    //      #expect(!result.isEmpty)
    //      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
    //      #expect(result == server.response as? [PTRRecord])
    //
    //      _ = try await p.queryPTR(name: "example.com")
    //      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
    //      #expect(result == server.response as? [PTRRecord])
    //    }
    //
    //    server.close(promise: nil)
    //    try await p.shutdownGracefully()
  }
}
