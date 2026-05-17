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
import NetbotDNS
import NetbotLiteData
import Testing

@testable import Netbot

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  import SynchronizationExtras
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
  final class MockTunnelFlow: PacketTunnelFlow {
    let writePacketObjects = Mutex<[NEPacket]>([])

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

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func handleInput() async throws {
    let options = LocalDNSProxy.Options(
      group: .shared,
      bindAddress: IPv4Address("198.18.1.1")!,
      additionalServers: [],
      mappings: [],
      availableIPPool: .init(bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    )
    let p = LocalDNSProxy(options: options)

    try await p.run()

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

    let reply = await p.handleNewPackets([query])
    #expect(!reply.isEmpty, "Should contains one reply packet")

    guard let packet = reply.first else {
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

    try await p.shutdownGracefully()
  }
}
