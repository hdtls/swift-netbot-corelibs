//
// See LICENSE.txt for license information
//

import Anlzr
import Atomics
import NEAddressProcessing
import NIOCore
import NIOEmbedded
import NIOPosix
import Testing
import _PrettyDNS

@testable import _NEAnalytics

@Suite(.tags(.dns))
struct LocalDNSProxyTests {

  final class MockDNSServer: Sendable {
    let queryCalls: ManagedAtomic<Int> = .init(0)
    let response: [any ResourceRecord]
    let parser = PrettyDNSParser()

    init(response: [any ResourceRecord]) {
      self.response = response
    }

    func start() async throws -> SocketAddress? {
      let channel = try await DatagramBootstrap(group: .singletonMultiThreadedEventLoopGroup)
        .bind(to: .init(ipAddress: "127.0.0.1", port: 0)) { channel in
          channel.eventLoop.makeCompletedFuture {
            try LocalDNSProxy.AsyncChannel(wrappingChannelSynchronously: channel)
          }
        }

      Task {
        try await channel.executeThenClose { inbound, outbound in
          for try await frame in inbound {
            // Always response privoded records.
            queryCalls.wrappingIncrement(ordering: .relaxed)
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
  }

  @Test func runQueryBeforeActive() async throws {
    let p = LocalDNSProxy(
      server: "198.18.0.1",
      additionalServers: [.hostPort(host: "1.1.1.1", port: 53)]
    )
    await #expect(throws: Never.self) {
      let name = "example.com"
      var result: [any ResourceRecord] = try await p.queryA(name: name)
      #expect(result.isEmpty)

      result = try await p.queryA(name: name)
      #expect(result.isEmpty)

      result = try await p.queryAAAA(name: name)
      #expect(result.isEmpty)

      result = try await p.queryNS(name: name)
      #expect(result.isEmpty)

      result = try await p.queryCNAME(name: name)
      #expect(result.isEmpty)

      result = try await p.querySOA(name: name)
      #expect(result.isEmpty)

      result = try await p.queryPTR(name: name)
      #expect(result.isEmpty)

      result = try await p.queryMX(name: name)
      #expect(result.isEmpty)

      result = try await p.queryTXT(name: name)
      #expect(result.isEmpty)

      result = try await p.querySRV(name: name)
      #expect(result.isEmpty)
    }
  }

  @Test func setResolverAfterActiveAutomatically() async throws {
    let p = LocalDNSProxy(server: "198.18.0.1", additionalServers: [])
    await #expect(p.channel == nil)
    try await p.runIfActive()
    await #expect(p.channel != nil)
  }

  @Test func packetHandling() async throws {
    let p = LocalDNSProxy(server: "116.116.116.116")
    try await p.runIfActive()

    let query = try IPPacket.v4(
      .init(
        data: .init(
          plainHexEncodedBytes:
            "45000042ec3100004011dd82c0a8076674747474f0960035002e24b4cca801200001000000000001057377696674036f726700000100010000291000000000000000"
        )))

    guard case .handled(let packet) = try await p.handle(query) else {
      #expect(Bool(false), "should handle correct DNS query")
      return
    }
    guard case .v4(let response) = packet else {
      return
    }
    #expect(response.internetHeaderLength == 5)
    #expect(response.differentiatedServicesCodePoint == 0)
    #expect(response.explicitCongestionNotification == 0)
    #expect(response.totalLength == 71)
    #expect(response.flags == 0)
    #expect(response.fragmentOffset == 0)
    #expect(response.timeToLive == 64)
    #expect(response.protocol == .udp)
    #expect(response.sourceAddress == .init("116.116.116.116")!)
    #expect(response.destinationAddress == .init("192.168.7.102")!)

    let datagram = Datagram(
      data: response.payload!,
      pseudoFields: .init(
        sourceAddress: .init("116.116.116.116")!,
        destinationAddress: .init("192.168.7.102")!,
        protocol: .udp,
        dataLength: 46
      )
    )
    #expect(datagram.sourcePort == 53)
    #expect(datagram.destinationPort == 61590)
    #expect(datagram.totalLength == 51)

    let message = Message(
      headerFields: .init(
        transactionID: 0xcca8,
        flags: .init(rawValue: 0x8000),
        qestionCount: 1,
        answerCount: 1,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [Question(domainName: "swift.org", queryType: .a)],
      answerRRs: [
        ARecord(
          domainName: "swift.org", ttl: 300, dataLength: .determined(4), data: .init("198.18.0.3")!)
      ],
      authorityRRs: [],
      additionalRRs: []
    )
    let serializedBytes = try message.serializedBytes
    #expect(datagram.payload == .init(bytes: serializedBytes))
  }

  @Test func queryA() async throws {
    let server = MockDNSServer(
      response: [
        ARecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(4),
          data: .init("123.123.123.123")!)
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.queryA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [ARecord])

      _ = try await p.queryA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [ARecord])
    }
  }

  @Test func handleExpiredARecord() async throws {
    let server = MockDNSServer(
      response: [
        ARecord(
          domainName: "example.com", ttl: 1, dataLength: .determined(4),
          data: .init("123.123.123.123")!)
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.queryA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)

      // Wait for expiration.
      try await Task.sleep(for: .seconds(1))

      _ = try await p.queryA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
    }
  }

  @Test func queryAAAA() async throws {
    let server = MockDNSServer(
      response: [
        AAAARecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(16), data: .init("::1")!)
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.queryAAAA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [AAAARecord])

      _ = try await p.queryAAAA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [AAAARecord])
    }
  }

  @Test func handleExpiredAAAARecord() async throws {
    let server = MockDNSServer(
      response: [AAAARecord(domainName: "example.com", ttl: 1, data: .init("::1")!)]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.queryAAAA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)

      // Wait for expiration.
      try await Task.sleep(for: .seconds(1))

      _ = try await p.queryAAAA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
    }
  }

  @Test func queryNS() async throws {
    let server = MockDNSServer(
      response: [
        NSRecord(domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.queryNS(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [NSRecord])

      _ = try await p.queryNS(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [NSRecord])
    }
  }

  @Test func queryCNAME() async throws {
    let server = MockDNSServer(
      response: [
        CNAMERecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.queryCNAME(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [CNAMERecord])

      _ = try await p.queryCNAME(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [CNAMERecord])
    }
  }

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
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.querySOA(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [SOARecord])

      _ = try await p.querySOA(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [SOARecord])
    }
  }

  @Test func queryPTR() async throws {
    let server = MockDNSServer(
      response: [
        PTRRecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.queryPTR(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [PTRRecord])

      _ = try await p.queryPTR(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [PTRRecord])
    }
  }

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
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.queryMX(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [MXRecord])

      _ = try await p.queryMX(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [MXRecord])
    }
  }

  @Test func queryTXT() async throws {
    let server = MockDNSServer(
      response: [
        TXTRecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(10), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.queryTXT(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [TXTRecord])

      _ = try await p.queryTXT(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [TXTRecord])
    }
  }

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
    let p = LocalDNSProxy(additionalServers: [address.address])
    try await p.runIfActive()

    await #expect(throws: Never.self) {
      let result = try await p.querySRV(name: "example.com")
      #expect(!result.isEmpty)
      #expect(server.queryCalls.load(ordering: .relaxed) == 1)
      #expect(result == server.response as? [SRVRecord])

      _ = try await p.querySRV(name: "example.com")
      #expect(server.queryCalls.load(ordering: .relaxed) == 2)
      #expect(result == server.response as? [SRVRecord])
    }
  }
}
