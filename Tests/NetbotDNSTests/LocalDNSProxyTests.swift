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
import NetbotLite
import NetbotLiteData
import NetbotProfile
import Synchronization
import Testing

@testable import NetbotDNS

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@Suite(.tags(.dns))
struct LocalDNSProxyTests {

  @available(SwiftStdlib 6.0, *)
  final class MockDNSServer: @unchecked Sendable {
    let queryCalls: Atomic<Int> = .init(0)
    let response: [any ResourceRecord]
    let parser = DNSParser()

    #if canImport(Network)
      private var channel: (any Channel)?
    #else
      private var channel:
        NIOAsyncChannel<
          AddressedEnvelope<ByteBuffer>, AddressedEnvelope<ByteBuffer>
        >?
    #endif

    init(response: [any ResourceRecord]) {
      self.response = response
    }

    func start() async throws -> Address? {
      #if canImport(Network)
        final class Responder: ChannelInboundHandler, Sendable {
          typealias InboundIn = ByteBuffer

          let server: MockDNSServer
          init(server: MockDNSServer) {
            self.server = server
          }

          func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let parseInput = unwrapInboundIn(data)
            server.queryCalls.wrappingAdd(1, ordering: .relaxed)

            do {
              let message = try server.parser.parse(parseInput)
              let response = Message(
                headerFields: .init(
                  transactionID: message.headerFields.transactionID,
                  flags: .init(rawValue: 0x8100),
                  questionCount: 1,
                  answerCount: UInt16(server.response.count),
                  authorityCount: 0,
                  additionCount: 0
                ),
                questions: message.questions,
                answerRRs: server.response,
                authorityRRs: [],
                additionalRRs: []
              )
              let data = try response.serializedBytes

              context.writeAndFlush(NIOAny(ByteBuffer(bytes: data)), promise: nil)
            } catch {
              context.close(promise: nil)
            }
          }
        }

        channel = try await NIOTSDatagramListenerBootstrap(group: .default)
          .childChannelInitializer { channel in
            channel.pipeline.addHandler(Responder(server: self))
          }
          .bind(to: .init(ipAddress: "127.0.0.1", port: 0))
          .get()

        return try channel?.localAddress?.asAddress()
      #else
        channel = try await DatagramBootstrap(group: .default)
          .bind(to: .init(ipAddress: "127.0.0.1", port: 0)) { channel in
            channel.eventLoop.makeCompletedFuture {
              try NIOAsyncChannel<
                AddressedEnvelope<ByteBuffer>, AddressedEnvelope<ByteBuffer>
              >(wrappingChannelSynchronously: channel)
            }
          }

        Task {
          try? await channel?.executeThenClose { inbound, outbound in
            for try await frame in inbound {
              // Always response privoded records.
              queryCalls.wrappingAdd(1, ordering: .relaxed)

              let parseInput = frame.data

              let message = try parser.parse(parseInput)

              let response = Message(
                headerFields: .init(
                  transactionID: message.headerFields.transactionID,
                  flags: .init(rawValue: 0x8100),
                  questionCount: 1,
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
        return try channel?.channel.localAddress?.asAddress()
      #endif
    }

    func close(promise: EventLoopPromise<Void>?) {
      #if canImport(Network)
        channel?.close(promise: promise)
      #else
        channel?.channel.close(promise: promise)
      #endif
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func queryA() async throws {
    let server = MockDNSServer(
      response: [
        ARecord(
          domainName: "example.com", ttl: 300,
          data: .init("123.123.123.123")!)
      ]
    )
    let address = try #require(await server.start())

    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [ARecord])

      _ = try await resolver.queryA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [ARecord])
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func handleExpiredARecord() async throws {
    let server = MockDNSServer(
      response: [
        ARecord(
          domainName: "example.com", ttl: 1,
          data: .init("123.123.123.123")!)
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)

      // Wait for expiration.
      try await Task.sleep(for: .seconds(1))

      _ = try await resolver.queryA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func queryAAAA() async throws {
    let server = MockDNSServer(
      response: [
        AAAARecord(
          domainName: "example.com", ttl: 300, data: .init("::1")!)
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryAAAA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [AAAARecord])

      _ = try await resolver.queryAAAA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [AAAARecord])
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func handleExpiredAAAARecord() async throws {
    let server = MockDNSServer(
      response: [AAAARecord(domainName: "example.com", ttl: 1, data: .init("::1")!)]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryAAAA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)

      // Wait for expiration.
      try await Task.sleep(for: .seconds(1))

      _ = try await resolver.queryAAAA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func queryNS() async throws {
    let server = MockDNSServer(
      response: [
        NSRecord(domainName: "example.com", ttl: 300, data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryNS(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [NSRecord])

      _ = try await resolver.queryNS(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [NSRecord])
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func queryCNAME() async throws {
    let server = MockDNSServer(
      response: [
        CNAMERecord(
          domainName: "example.com", ttl: 300, data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryCNAME(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [CNAMERecord])

      _ = try await resolver.queryCNAME(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [CNAMERecord])
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func querySOA() async throws {
    let server = MockDNSServer(
      response: [
        SOARecord(
          domainName: "example.com", ttl: 300,
          data: .init(
            primaryNameServer: "primary.example.com", responsibleMailbox: "mx.example.com",
            serialNumber: 0, refreshInterval: 0, retryInterval: 0, expirationTime: 0, ttl: 300))
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.querySOA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [SOARecord])

      _ = try await resolver.querySOA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [SOARecord])
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      ["92.82.12.172.in-addr.arpa", "2001:0db8:1234:1a00:0000:0000:0000:0001.in6-addr.arpa"],
      ["example.com", "example.com"]))
  func queryPTR(query: String, response: String) async throws {
    let server = MockDNSServer(
      response: [
        PTRRecord(
          domainName: query, ttl: 300, data: response)
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryPTR(name: query)
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [PTRRecord])

      _ = try await resolver.queryPTR(name: query)
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [PTRRecord])
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func queryDisguisedIPv4PTR() async throws {
    let server = MockDNSServer(
      response: []
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryPTR(name: "6.1.18.169.in-addr.arpa")
      #expect(result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)

      _ = try await resolver.queryPTR(name: "6.1.18.169.in-addr.arpa")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
    }

    let response = [
      PTRRecord(
        domainName: "6.1.18.198.in-addr.arpa", ttl: 0,
        data: "example.com")
    ]
    resolver.disguisedARecords
      .setValue(
        .init(.init(domainName: "example.com", ttl: 0, data: IPv4Address("198.18.1.6")!)),
        forKey: "example.com")

    await #expect(throws: Never.self) {
      let result = try await resolver.queryPTR(name: "6.1.18.198.in-addr.arpa")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == response)
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func queryMX() async throws {
    let server = MockDNSServer(
      response: [
        MXRecord(
          domainName: "example.com",
          ttl: 300,
          data: .init(
            preference: 10,
            exchange: "1.exp.com"
          )
        )
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryMX(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [MXRecord])

      _ = try await resolver.queryMX(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [MXRecord])
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func queryTXT() async throws {
    let server = MockDNSServer(
      response: [
        TXTRecord(
          domainName: "example.com", ttl: 300, data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.queryTXT(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [TXTRecord])

      _ = try await resolver.queryTXT(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [TXTRecord])
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func querySRV() async throws {
    let server = MockDNSServer(
      response: [
        SRVRecord(
          domainName: "example.com", ttl: 300,
          data: .init(priority: 0, weight: 0, port: 33, hostname: "1.exp.com"))
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.querySRV(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [SRVRecord])

      _ = try await resolver.querySRV(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [SRVRecord])
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func initiateAQuery() async throws {
    let server = MockDNSServer(
      response: [
        ARecord(
          domainName: "example.com", ttl: 300,
          data: .init("123.123.123.123")!)
      ]
    )
    let address = try #require(await server.start())

    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.initiateAQuery(host: "example.com", port: 443).get()
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)

      let expected = try (server.response as? [ARecord])?.compactMap {
        try SocketAddress(ipAddress: "\($0.data)", port: 443)
      }
      #expect(result == expected)
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func initiateAAAAQuery() async throws {
    let server = MockDNSServer(
      response: [
        AAAARecord(
          domainName: "example.com", ttl: 300, data: .init("::1")!)
      ]
    )
    let address = try #require(await server.start())
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [address],
        mappings: [],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    await #expect(throws: Never.self) {
      let result = try await resolver.initiateAAAAQuery(host: "example.com", port: 443).get()
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)

      let expected = try (server.response as? [AAAARecord])?.compactMap {
        try SocketAddress(ipAddress: "\($0.data)", port: 443)
      }
      #expect(result == expected)
    }

    server.close(promise: nil)
    try await resolver.shutdownGracefully()
  }

  @available(SwiftStdlib 6.0, *)
  @Test func rejectResponseMessage() async throws {
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
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
      let result = try await resolver.query(msg: message)
      #expect(result.headerFields.flags.responseCode == .formErr)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func handleOnlyQueryOperations() async throws {
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
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
      let result = try await resolver.query(msg: message)
      #expect(result.headerFields.flags.responseCode == .notImp)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func standardServerOnlyHandleMessageWithExactlyOneQuestion() async throws {
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
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
      let result = try await resolver.query(msg: message)
      #expect(result.headerFields.flags.responseCode == .formErr)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func aAddressMapping() async throws {
    let mapping = ProtocolDNS.Mapping(
      strategy: .mapping, domainName: "localhost", value: "127.0.0.1", note: "")
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [],
        mappings: [mapping],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    let expected = Message(
      headerFields: .init(
        transactionID: 0x1165,
        flags: .init(
          response: false,
          operationCode: .query,
          authoritative: false,
          truncated: false,
          recursionDesired: false,
          recursionAvailable: false,
          authenticatedData: false,
          checkingDisabled: true,
          responseCode: .noError
        ),
        questionCount: 1,
        answerCount: 1,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [.init(domainName: "localhost", queryType: .a)],
      answerRRs: [
        ARecord(
          domainName: "localhost", ttl: 0,
          data: IPv4Address(mapping.value)!)
      ],
      authorityRRs: [],
      additionalRRs: []
    )
    let response = try await resolver.query(
      msg: .init(
        transactionID: 0x1165,
        response: false,
        questions: expected.questions
      )
    )

    #expect(response.headerFields.questionCount == expected.headerFields.questionCount)
    #expect(response.headerFields.answerCount == expected.headerFields.answerCount)
    #expect(response.questions == expected.questions)
    #expect(response.answerRRs as! [ARecord] == expected.answerRRs as! [ARecord])
  }

  @available(SwiftStdlib 6.0, *)
  @Test func aaaaAddressMapping() async throws {
    let mapping = ProtocolDNS.Mapping(
      strategy: .mapping, domainName: "localhost", value: "::1", note: "")
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [],
        mappings: [mapping],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    let expected = Message(
      headerFields: .init(
        transactionID: 0x1165,
        flags: .init(
          response: false,
          operationCode: .query,
          authoritative: false,
          truncated: false,
          recursionDesired: false,
          recursionAvailable: false,
          authenticatedData: false,
          checkingDisabled: true,
          responseCode: .noError
        ),
        questionCount: 1,
        answerCount: 1,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [.init(domainName: "localhost", queryType: .aaaa)],
      answerRRs: [
        AAAARecord(
          domainName: "localhost", ttl: 0,
          data: IPv6Address(mapping.value)!)
      ],
      authorityRRs: [],
      additionalRRs: []
    )
    let response = try await resolver.query(
      msg: .init(
        transactionID: 0x1165,
        response: false,
        questions: expected.questions
      )
    )

    #expect(response.headerFields.questionCount == expected.headerFields.questionCount)
    #expect(response.headerFields.answerCount == expected.headerFields.answerCount)
    #expect(response.questions == expected.questions)
    #expect(response.answerRRs as! [AAAARecord] == expected.answerRRs as! [AAAARecord])
  }

  @available(SwiftStdlib 6.0, *)
  @Test func cnameMapping() async throws {
    let mapping = ProtocolDNS.Mapping(
      strategy: .cname, domainName: "example.com", value: "test.com", note: "")
    let resolver = LocalDNSProxy(
      options: .init(
        group: .default,
        bindAddress: IPv4Address("198.18.0.2")!,
        additionalServers: [],
        mappings: [mapping],
        availableIPPool: AvailableIPPool(
          bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
        )
      )
    )
    try await resolver.run()

    let expected = Message(
      headerFields: .init(
        transactionID: 0x1165,
        flags: .init(
          response: false,
          operationCode: .query,
          authoritative: false,
          truncated: false,
          recursionDesired: false,
          recursionAvailable: false,
          authenticatedData: false,
          checkingDisabled: true,
          responseCode: .noError
        ),
        questionCount: 1,
        answerCount: 1,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [.init(domainName: "example.com", queryType: .aaaa)],
      answerRRs: [CNAMERecord(domainName: "example.com", ttl: 0, data: "test.com")],
      authorityRRs: [],
      additionalRRs: []
    )
    let response = try await resolver.query(
      msg: .init(
        transactionID: 0x1165,
        response: false,
        questions: expected.questions
      )
    )

    #expect(response.headerFields.questionCount == expected.headerFields.questionCount)
    #expect(response.headerFields.answerCount == expected.headerFields.answerCount)
    #expect(response.questions == expected.questions)
    #expect(response.answerRRs as! [CNAMERecord] == expected.answerRRs as! [CNAMERecord])
  }
}
