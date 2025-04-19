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

  @Test func directlyPacketHandling() async throws {
    let p = LocalDNSProxy(server: "198.18.1.1")
    try await p.runIfActive()

    let message = Message(
      headerFields: .init(
        transactionID: 0,
        flags: .init(rawValue: 0x8180),
        qestionCount: 1,
        answerCount: 0,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [Question(domainName: "example.com", queryType: .a)],
      answerRRs: [],
      authorityRRs: [],
      additionalRRs: []
    )
    let serializedBytes = try message.serializedBytes

    var datagram = Datagram(
      pseudoFields: .init(
        sourceAddress: .init("198.18.0.1")!,
        destinationAddress: .init("198.18.1.1")!,
        protocol: .udp,
        dataLength: UInt16(serializedBytes.count + 8)
      )
    )
    datagram.sourcePort = 12345
    datagram.destinationPort = 53
    datagram.payload = ByteBuffer(bytes: serializedBytes)
    #expect(datagram.totalLength == serializedBytes.count + 8)

    var query = IPPacket.IPv4Packet()
    query.differentiatedServicesCodePoint = 0
    query.explicitCongestionNotification = 0
    query.identification = .random(in: 0...UInt16.max)
    query.timeToLive = 64
    query.protocol = .udp
    query.sourceAddress = datagram.pseudoFields.sourceAddress
    query.destinationAddress = datagram.pseudoFields.destinationAddress
    query.options = nil
    query.payload = datagram.data

    await #expect(throws: Never.self) {
      guard case .handled(let packet) = try await p.handle(.v4(query)) else {
        #expect(Bool(false), "Should handle correct DNS query packet.")
        return
      }

      guard case .v4(let response) = packet else {
        #expect(Bool(false), "Should be IPv4 packet")
        return
      }

      let message = Message(
        headerFields: .init(
          transactionID: 0,
          flags: .init(rawValue: 0x8000),
          qestionCount: 1,
          answerCount: 1,
          authorityCount: 0,
          additionCount: 0
        ),
        questions: [Question(domainName: "example.com", queryType: .a)],
        answerRRs: [
          ARecord(
            domainName: "example.com", ttl: 300, dataLength: .determined(4),
            data: IPv4Address("198.18.0.3")!)
        ],
        authorityRRs: [],
        additionalRRs: []
      )
      let serializedBytes = try message.serializedBytes
      #expect(serializedBytes.count == 45)

      var datagram = Datagram(
        pseudoFields: .init(
          sourceAddress: .init("198.18.1.1")!,
          destinationAddress: .init("198.18.0.1")!,
          protocol: .udp,
          dataLength: UInt16(serializedBytes.count + 8)
        )
      )
      datagram.sourcePort = 53
      datagram.destinationPort = 12345
      datagram.payload = ByteBuffer(bytes: serializedBytes)
      #expect(datagram.totalLength == 53)

      #expect(response.internetHeaderLength == 5)
      #expect(response.differentiatedServicesCodePoint == 0)
      #expect(response.differentiatedServicesCodePoint == 0)
      #expect(response.totalLength == 73)
      #expect(response.flags == 0)
      #expect(response.fragmentOffset == 0)
      #expect(response.timeToLive == 64)
      #expect(response.protocol == .udp)
      #expect(response.sourceAddress == datagram.pseudoFields.sourceAddress)
      #expect(response.destinationAddress == datagram.pseudoFields.destinationAddress)
      #expect(response.options == nil)
      #expect(response.payload == datagram.data)
    }
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
