//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Dispatch
import Logging
import NEAddressProcessing
import NIOCore
import _PrettyDNS

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
actor LocalDNSProxy: PacketHandle {

  let allocator: ByteBufferAllocator

  private let parser = PrettyDNSParser()
  private let aTaskMap: LRUCache<String, Task<[Expirable<ARecord>], any Error>>
  private let aaaaTaskMap: LRUCache<String, Task<[Expirable<AAAARecord>], any Error>>
  private let soaTaskMap: LRUCache<String, Task<[Expirable<SOARecord>], any Error>>

  private let bindAddress: String
  private let additionalServers: [String]
  private let availableIPPool: AvailableIPPool

  internal var resolver: (any Resolver & Sendable)? = .none

  private let logger = Logger(label: "dns")

  init(
    allocator: ByteBufferAllocator,
    server: String,
    additionalServers: [String]
  ) {
    self.allocator = allocator
    self.bindAddress = server
    self.additionalServers = additionalServers
    self.availableIPPool = .init(
      bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
    self.aTaskMap = .init(capacity: 200)
    self.aaaaTaskMap = .init(capacity: 200)
    self.soaTaskMap = .init(capacity: 50)
  }

  func runIfActive() async throws {
    var options = DNSResolver.Options.default
    options.servers = additionalServers
    self.resolver = try DNSResolver(options: options)
  }

  func handle(_ packetObject: IPPacket) async throws -> PacketHandleResult {
    // Make it mutable, so we don't need alloc new packet for response.
    guard case .v4(var packet) = packetObject else {
      // IPv4 only now.
      return .discarded
    }

    // Large DNS query over TCP is not supported yet.
    guard packet.protocol == .udp else {
      return .discarded
    }

    // Make sure the packet contains transport layer data.
    guard let payload = packet.payload, payload.count >= MemoryLayout<UInt16>.size * 4 else {
      return .discarded
    }

    // Make it mutable, so we don't need alloc another datagram for response.
    var datagram = Datagram(
      data: payload,
      pseudoFields: .init(
        sourceAddress: packet.sourceAddress,
        destinationAddress: packet.destinationAddress,
        protocol: packet.protocol,
        dataLength: UInt16(payload.count)
      )
    )

    // Store address to make response by exchange source/destination address and port.
    let destinationAddress = packet.destinationAddress
    let destinationPort = datagram.destinationPort
    guard IPv4Address(bindAddress) == destinationAddress, destinationPort == 53 else {
      return .discarded
    }

    guard let dnsPayload = datagram.payload else {
      // TODO: Handle Missing Data Error.
      return .discarded
    }

    var message = try parser.parse(dnsPayload)

    // All communications inside of the domain protocol are carried in the same
    // message format, so we can modify query message to make response message.
    message.headerFields.flags = .init(rawValue: 0x8181)
    message.headerFields.answerCount = 1
    message.headerFields.authorityCount = 0
    message.headerFields.additionCount = 0
    message.answerRRs = message.questions.compactMap { question in
      guard case .a = question.queryType else {
        return nil
      }
      return ARecord(
        domainName: question.domainName,
        ttl: 0,
        dataLength: .determined(4),
        data: availableIPPool.loadThenWrappingIncrement()
      )
    }
    message.authorityRRs = []
    message.additionalRRs = []

    datagram.sourcePort = destinationPort
    datagram.destinationPort = datagram.sourcePort
    datagram.payload = try allocator.buffer(bytes: message.serializedBytes)
    datagram.pseudoFields.sourceAddress = destinationAddress
    datagram.pseudoFields.destinationAddress = datagram.pseudoFields.sourceAddress
    datagram.pseudoFields.protocol = datagram.pseudoFields.protocol
    datagram.pseudoFields.dataLength = datagram.totalLength

    packet.internetHeaderLength = 5
    packet.differentiatedServicesCodePoint = 0
    packet.explicitCongestionNotification = 0
    packet.identification = .random(in: 0xC000 ... .max)
    packet.flags = 0
    packet.fragmentOffset = 0
    packet.timeToLive = 1
    packet.destinationAddress = packet.sourceAddress
    packet.sourceAddress = destinationAddress
    packet.options = nil
    packet.payload = datagram.data

    return .handled(.v4(packet))
  }

  func queryA(name: String) async throws -> [ARecord] {
    guard let task = aTaskMap.value(forKey: name) else {
      return try await _queryA(name: name).map { $0.record }
    }

    let expirables: [Expirable<ARecord>]
    do {
      expirables = try await task.value.filter { !$0.isExpired }
    } catch {
      // If cached task result in failure, we should remove it from cache and start a fresh request.
      aTaskMap.removeValue(forKey: name)
      expirables = []
    }
    guard expirables.isEmpty else {
      return expirables.map { $0.record }
    }

    return try await _queryA(name: name).map { $0.record }
  }

  private func _queryA(name: String) async throws -> [Expirable<ARecord>] {
    guard let resolver else { return [] }

    let task = Task<[Expirable<ARecord>], any Error> {
      try await resolver.queryA(name: name).map {
        Expirable($0)
      }
    }
    aTaskMap.setValue(task, forKey: name)
    return try await task.value
  }

  func queryAAAA(name: String) async throws -> [AAAARecord] {
    guard let task = aaaaTaskMap.value(forKey: name) else {
      return try await self._queryAAAA(name: name).map { $0.record }
    }

    let expirables: [Expirable<AAAARecord>]
    do {
      expirables = try await task.value.filter { !$0.isExpired }
    } catch {
      // If cached task result in failure, we should remove it from cache and start a fresh request.
      aaaaTaskMap.removeValue(forKey: name)
      expirables = []
    }
    guard expirables.isEmpty else {
      return expirables.map { $0.record }
    }
    return try await self._queryAAAA(name: name).map { $0.record }
  }

  private func _queryAAAA(name: String) async throws -> [Expirable<AAAARecord>] {
    guard let resolver else { return [] }

    let task = Task<[Expirable<AAAARecord>], any Error> {
      try await resolver.queryAAAA(name: name).map {
        Expirable($0)
      }
    }
    aaaaTaskMap.setValue(task, forKey: name)
    return try await task.value
  }

  func queryNS(name: String) async throws -> [NSRecord] {
    guard let resolver else { return [] }
    return try await resolver.queryNS(name: name)
  }

  func queryCNAME(name: String) async throws -> [CNAMERecord] {
    guard let resolver else { return [] }
    return try await resolver.queryCNAME(name: name)
  }

  func querySOA(name: String) async throws -> [SOARecord] {
    guard let task = soaTaskMap.value(forKey: name) else {
      return try await self._querySOA(name: name).map { $0.record }
    }

    let expirables: [Expirable<SOARecord>]
    do {
      expirables = try await task.value.filter { !$0.isExpired }
    } catch {
      soaTaskMap.removeValue(forKey: name)
      expirables = []
    }
    guard expirables.isEmpty else {
      return expirables.map { $0.record }
    }
    return try await self._querySOA(name: name).map { $0.record }
  }

  private func _querySOA(name: String) async throws -> [Expirable<SOARecord>] {
    guard let resolver else { return [] }

    let task = Task {
      try await resolver.querySOA(name: name).map {
          Expirable($0)
        }
    }
    soaTaskMap.setValue(task, forKey: name)
    return try await task.value
  }

  func queryPTR(name: String) async throws -> [PTRRecord] {
    guard let resolver else { return [] }
    return try await resolver.queryPTR(name: name)
  }

  func queryMX(name: String) async throws -> [MXRecord] {
    guard let resolver else { return [] }
    return try await resolver.queryMX(name: name)
  }

  func queryTXT(name: String) async throws -> [TXTRecord] {
    guard let resolver else { return [] }
    return try await resolver.queryTXT(name: name)
  }

  func querySRV(name: String) async throws -> [SRVRecord] {
    guard let resolver else { return [] }
    return try await resolver.querySRV(name: name)
  }
}

private struct Expirable<Record: ResourceRecord>: Sendable {

  var record: Record

  private let time = DispatchTime.now()

  var isExpired: Bool {
    return time + Double(record.ttl) < .now()
  }

  init(_ record: Record) {
    self.record = record
  }
}
