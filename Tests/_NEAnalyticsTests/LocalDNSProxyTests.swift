//
// See LICENSE.txt for license information
//

import AnlzrReports
import Atomics
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore
import NIOEmbedded
import NIOPosix
import Testing
import _DNSSupport

@testable import _NEAnalytics

@Suite(.tags(.dns))
struct LocalDNSProxyTests {

  final class MockTunnelFlow: PacketTunnelFlow {
    let writePacketObjects = NIOLockedValueBox<[NEPacket]>([])

    func readPacketObjects() async -> [NEPacket] {
      []
    }

    func writePacketObjects(_ packets: [NEPacket]) -> Bool {
      writePacketObjects.withLock {
        $0.append(contentsOf: packets)
      }
      return true
    }
  }

  final class MockDNSServer: @unchecked Sendable {
    let queryCalls: ManagedAtomic<Int> = .init(0)
    let response: [any ResourceRecord]
    let parser = PrettyDNSParser()
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

    func close(promise: EventLoopPromise<Void>?) {
      channel.channel.close(promise: promise)
    }
  }

  @Test func handleInput() async throws {
    let packetFlow = MockTunnelFlow()
    let p = LocalDNSProxy(
      packetFlow: packetFlow,
      server: IPv4Address("198.18.1.1")!,
      additionalServers: [Address](),
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
    try await p.runIfActive()

    var message = Message(
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
    var serializedBytes = try message.serializedBytes

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

    var bytes = ByteBuffer(repeating: 0, count: 20)
    bytes.setInteger(0x45, at: 0, as: UInt8.self)
    bytes.setInteger(20, at: 2, as: UInt16.self)
    var queryHeaderFields = NEIPFields.NEInFields(storage: bytes)
    queryHeaderFields.explicitCongestionNotification = 0
    queryHeaderFields.identification = .random(in: 0...UInt16.max)
    queryHeaderFields.timeToLive = 64
    queryHeaderFields.protocol = .udp
    queryHeaderFields.sourceAddress = datagram.pseudoFields.sourceAddress
    queryHeaderFields.destinationAddress = datagram.pseudoFields.destinationAddress
    queryHeaderFields.options = nil
    queryHeaderFields.totalLength = UInt16(20 + datagram.data.count)

    var queryData = queryHeaderFields.data
    queryData.append(contentsOf: datagram.data)
    let query = try #require(NEPacket(data: queryData, protocolFamily: .inet))
    guard case .handled = try await p.handleInput(query) else {
      #expect(Bool(false), "Should handle correct DNS query packet.")
      return
    }

    guard let packet = packetFlow.writePacketObjects.withLock({ $0.first }) else {
      #expect(Bool(false), "Should be IPv4 packet")
      return
    }
    guard case .v4(let response) = packet.headerFields else {
      #expect(Bool(false), "Should be IPv4 packet")
      return
    }

    message = Message(
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
    serializedBytes = try message.serializedBytes
    #expect(serializedBytes.count == 45)

    datagram = Datagram(
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
    #expect(packet.payload == datagram.data)

    p.close(promise: nil)
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

    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
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
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
  }

  @Test func queryAAAA() async throws {
    let server = MockDNSServer(
      response: [
        AAAARecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(16), data: .init("::1")!)
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
  }

  @Test func handleExpiredAAAARecord() async throws {
    let server = MockDNSServer(
      response: [AAAARecord(domainName: "example.com", ttl: 1, data: .init("::1")!)]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
  }

  @Test func queryNS() async throws {
    let server = MockDNSServer(
      response: [
        NSRecord(domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
  }

  @Test func queryCNAME() async throws {
    let server = MockDNSServer(
      response: [
        CNAMERecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
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
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
  }

  @Test func queryPTR() async throws {
    let server = MockDNSServer(
      response: [
        PTRRecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(8), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
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
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
  }

  @Test func queryTXT() async throws {
    let server = MockDNSServer(
      response: [
        TXTRecord(
          domainName: "example.com", ttl: 300, dataLength: .determined(10), data: "1.exp.com")
      ]
    )
    let address = try #require(await server.start())
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
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
    let p = LocalDNSProxy(
      packetFlow: MockTunnelFlow(),
      server: IPv4Address("198.18.0.2")!,
      additionalServers: [try address.asAddress()],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
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

    server.close(promise: nil)
    p.close(promise: nil)
  }
}
