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
  private let availableAQueries: LRUCache<String, Task<[Expirable<ARecord>], any Error>>
  private let disguisedARecords: LRUCache<String, Expirable<ARecord>>
  private let availableAAAAQueries: LRUCache<String, Task<[Expirable<AAAARecord>], any Error>>
  private let availableSOAQueries: LRUCache<String, Task<[Expirable<SOARecord>], any Error>>
  private let availablePTRQueries: LRUCache<String, Task<[Expirable<PTRRecord>], any Error>>

  private let bindAddress: String
  private let additionalServers: [String]
  private let availableIPPool: AvailableIPPool

  internal var resolver: (any Resolver & Sendable)? = .none

  private let logger = Logger(label: "dns")

  init(
    allocator: ByteBufferAllocator = .init(),
    server: String = "198.18.0.2",
    additionalServers: [String] = [],
    availableIPPool: AvailableIPPool = .init(
      bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!))
  ) {
    self.allocator = allocator
    self.bindAddress = server
    self.additionalServers = additionalServers
    self.availableIPPool = availableIPPool
    self.availableAQueries = .init(capacity: 200)
    self.availableAAAAQueries = .init(capacity: 200)
    self.availableSOAQueries = .init(capacity: 50)
    self.availablePTRQueries = .init(capacity: 200)
    self.disguisedARecords = .init(capacity: 200)
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

    guard let dnsPayload = datagram.payload, !dnsPayload.isEmpty else {
      // TODO: Handle Missing Data Error.
      return .discarded
    }

    var message = try parser.parse(dnsPayload)

    logger
      .debug(
        "[\(packet.identification)] \(packet.protocol) \(packet.sourceAddress) => \(packet.destinationAddress) Receive DNS query message: \(message)"
      )
    let questions = message.questions
    let answerRRs = await withTaskGroup(of: [any ResourceRecord].self) { g in
      for question in questions {
        g.addTask { [self] in
          do {
            switch question.queryType {
            case .a:
              return try await self.queryA0(name: question.domainName)
            case .ns:
              return try await self.queryNS(name: question.domainName)
            case .cname:
              return try await self.queryCNAME(name: question.domainName)
            case .soa:
              return try await self.querySOA(name: question.domainName)
            case .ptr:
              return try await self.queryPTR(name: question.domainName)
            case .mx:
              return try await self.queryMX(name: question.domainName)
            case .txt:
              return try await self.queryTXT(name: question.domainName)
            case .aaaa:
              return try await self.queryAAAA(name: question.domainName)
            case .srv:
              return try await self.querySRV(name: question.domainName)
            default:
              return []
            }
          } catch {
            return []
          }
        }
      }

      var results: [any ResourceRecord] = []
      for await rr in g {
        results += rr
      }
      return results
    }

    // All communications inside of the domain protocol are carried in the same
    // message format, so we can modify query message to make response message.
    message.headerFields.flags = .init(
      response: true,
      opcode: 0,
      authoritative: false,
      truncated: false,
      recursionDesired: true,
      recursionAvailable: true,
      authenticatedData: false,
      checkingDisabled: false,
      responseCode: 0
    )
    message.headerFields.answerCount = 1
    message.headerFields.authorityCount = 0
    message.headerFields.additionCount = 0
    message.answerRRs = answerRRs
    message.authorityRRs = []
    message.additionalRRs = []

    datagram.destinationPort = datagram.sourcePort
    datagram.sourcePort = destinationPort
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
    packet.timeToLive = 5
    packet.destinationAddress = packet.sourceAddress
    packet.sourceAddress = destinationAddress
    packet.options = nil
    packet.payload = datagram.data

    logger
      .debug(
        "[\(packet.identification)] \(packet.protocol) \(packet.sourceAddress) => \(packet.destinationAddress) Response DNS query message: \(message)"
      )

    return .handled(.v4(packet))
  }

  internal func setResolver(_ resolver: any Resolver & Sendable) {
    self.resolver = resolver
  }

  // Returns disguised records contains one reserved IPv4 address.
  private func queryA0(name: String) async throws -> [ARecord] {
    Task(priority: .background) {
      // Query and update actual A records.
      _ = try await queryA(name: name)
    }

    var value: Expirable<ARecord>
    if let stored = disguisedARecords.value(forKey: name), !stored.isExpired {
      value = stored
      value.time = .now()
    } else {
      value = Expirable(
        ARecord(domainName: name, ttl: 10, data: availableIPPool.loadThenWrappingIncrement())
      )
    }

    disguisedARecords.setValue(value, forKey: name)
    return [value.record]
  }
}

extension LocalDNSProxy: Resolver {

  func queryA(name: String) async throws -> [ARecord] {
    guard let task = availableAQueries.value(forKey: name) else {
      return try await _queryA(name: name).map(\.record)
    }

    let expirables: [Expirable<ARecord>]
    do {
      expirables = try await task.value.filter { !$0.isExpired }
    } catch {
      // If cached task result in failure, we should remove it from cache and start a fresh request.
      availableAQueries.removeValue(forKey: name)
      expirables = []
    }
    guard expirables.isEmpty else {
      return expirables.map(\.record)
    }

    return try await _queryA(name: name).map(\.record)
  }

  private func _queryA(name: String) async throws -> [Expirable<ARecord>] {
    guard let resolver else { return [] }

    let task = Task<[Expirable<ARecord>], any Error> {
      try await resolver.queryA(name: name).map {
        Expirable($0)
      }
    }
    availableAQueries.setValue(task, forKey: name)
    return try await task.value
  }

  func queryAAAA(name: String) async throws -> [AAAARecord] {
    guard let task = availableAAAAQueries.value(forKey: name) else {
      return try await self._queryAAAA(name: name).map(\.record)
    }

    let expirables: [Expirable<AAAARecord>]
    do {
      expirables = try await task.value.filter { !$0.isExpired }
    } catch {
      // If cached task result in failure, we should remove it from cache and start a fresh request.
      availableAAAAQueries.removeValue(forKey: name)
      expirables = []
    }
    guard expirables.isEmpty else {
      return expirables.map { $0.record }
    }
    return try await self._queryAAAA(name: name).map(\.record)
  }

  private func _queryAAAA(name: String) async throws -> [Expirable<AAAARecord>] {
    guard let resolver else { return [] }

    let task = Task<[Expirable<AAAARecord>], any Error> {
      try await resolver.queryAAAA(name: name).map {
        Expirable($0)
      }
    }
    availableAAAAQueries.setValue(task, forKey: name)
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
    guard let task = availableSOAQueries.value(forKey: name) else {
      return try await self._querySOA(name: name).map(\.record)
    }

    let expirables: [Expirable<SOARecord>]
    do {
      expirables = try await task.value.filter { !$0.isExpired }
    } catch {
      availableSOAQueries.removeValue(forKey: name)
      expirables = []
    }
    guard expirables.isEmpty else {
      return expirables.map(\.record)
    }
    return try await self._querySOA(name: name).map(\.record)
  }

  private func _querySOA(name: String) async throws -> [Expirable<SOARecord>] {
    guard let resolver else { return [] }

    let task = Task {
      try await resolver.querySOA(name: name).map {
        Expirable($0)
      }
    }
    availableSOAQueries.setValue(task, forKey: name)
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

  var time = DispatchTime.now()

  var isExpired: Bool {
    return time + Double(record.ttl) < .now()
  }

  init(_ record: Record) {
    self.record = record
  }
}
