//
// See LICENSE.txt for license information
//

#if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  import NIOCore
  import AsyncDNSResolver
  import NEAddressProcessing
  import AnlzrReports
  import Dispatch
  import _PrettyDNS

  internal typealias ARecord = _PrettyDNS.ARecord
  internal typealias NSRecord = _PrettyDNS.NSRecord
  internal typealias CNAMERecord = _PrettyDNS.CNAMERecord
  internal typealias SOARecord = _PrettyDNS.SOARecord
  internal typealias PTRRecord = _PrettyDNS.PTRRecord
  internal typealias MXRecord = _PrettyDNS.MXRecord
  internal typealias TXTRecord = _PrettyDNS.TXTRecord
  internal typealias AAAARecord = _PrettyDNS.AAAARecord
  internal typealias SRVRecord = _PrettyDNS.SRVRecord
  internal typealias NAPTRRecord = _PrettyDNS.NAPTRRecord

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  actor LocalDNSProxy: PacketHandle {

    let allocator: ByteBufferAllocator

    private let parser = PrettyDNSParser()
    private let aTaskMap: LRUCache<String, Task<[Expirable<ARecord>], any Error>>
    private let aaaaTaskMap: LRUCache<String, Task<[Expirable<AAAARecord>], any Error>>
    private let soaTaskMap: LRUCache<String, Task<Expirable<SOARecord>?, any Error>>

    private let bindAddress: String
    private let additionalServers: [String]
    private let availableIPPool: AvailableIPPool
    private var resolver: (any DNSResolver & Sendable)? = .none

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
      var options = CAresDNSResolver.Options.default
      options.servers = additionalServers
      self.resolver = try AsyncDNSResolver(options: options)
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
      guard let resolver else { fatalError("\(self) is inactive.") }

      let task = Task<[Expirable<ARecord>], any Error> {
        try await resolver.queryA(name: name).compactMap {
          guard let address = IPv4Address($0.address.address) else { return nil }
          return Expirable(
            ARecord(domainName: name, ttl: $0.ttl ?? 1, dataLength: .determined(4), data: address)
          )
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
      guard let resolver else { fatalError("\(self) is inactive.") }

      let task = Task<[Expirable<AAAARecord>], any Error> {
        try await resolver.queryAAAA(name: name).compactMap {
          guard let address = IPv6Address($0.address.address) else { return nil }
          return Expirable(
            AAAARecord(
              domainName: name, ttl: $0.ttl ?? 0, dataLength: .determined(16), data: address)
          )
        }
      }
      aaaaTaskMap.setValue(task, forKey: name)
      return try await task.value
    }

    func queryNS(name: String) async throws -> [NSRecord] {
      guard let resolver else { fatalError("\(self) is inactive.") }

      return try await resolver.queryNS(name: name).nameservers.map {
        NSRecord(domainName: name, ttl: 0, data: $0)
      }
    }

    func queryCNAME(name: String) async throws -> CNAMERecord? {
      guard let resolver else { fatalError("\(self) is inactive.") }

      guard let cname = try await resolver.queryCNAME(name: name) else { return nil }
      return CNAMERecord(domainName: name, ttl: 0, data: cname)
    }

    func querySOA(name: String) async throws -> SOARecord? {
      guard let task = soaTaskMap.value(forKey: name) else {
        return try await self._querySOA(name: name)?.record
      }

      var expirable: Expirable<SOARecord>?
      do {
        expirable = try await task.value
      } catch {
        soaTaskMap.removeValue(forKey: name)
      }
      guard expirable?.isExpired ?? true else {
        return expirable?.record
      }

      return try await self._querySOA(name: name)?.record
    }

    private func _querySOA(name: String) async throws -> Expirable<SOARecord>? {
      guard let resolver else { fatalError("\(self) is inactive.") }

      let task = Task {
        try await resolver
          .querySOA(name: name)
          .map {
            Expirable(
              SOARecord(
                domainName: name,
                ttl: 0,
                data: .init(
                  primaryNameServer: $0.mname ?? "",
                  responsibleMailbox: $0.rname ?? "",
                  serialNumber: $0.serial,
                  refreshInterval: $0.refresh,
                  retryInterval: $0.retry,
                  expirationTime: $0.expire,
                  ttl: $0.ttl
                )
              )
            )
          }
      }
      soaTaskMap.setValue(task, forKey: name)
      return try await task.value
    }

    func queryPTR(name: String) async throws -> [PTRRecord] {
      guard let resolver else { fatalError("\(self) is inactive.") }

      return try await resolver.queryPTR(name: name).names.map {
        PTRRecord(domainName: name, ttl: 0, data: $0)
      }
    }

    func queryMX(name: String) async throws -> [MXRecord] {
      guard let resolver else { fatalError("\(self) is inactive.") }

      return try await resolver.queryMX(name: name).map {
        MXRecord(
          domainName: name,
          ttl: 0,
          data: .init(preference: $0.priority, exchange: $0.host)
        )
      }
    }

    func queryTXT(name: String) async throws -> [TXTRecord] {
      guard let resolver else { fatalError("\(self) is inactive.") }

      return try await resolver.queryTXT(name: name).map {
        TXTRecord(domainName: name, ttl: 0, data: $0.txt)
      }
    }

    func querySRV(name: String) async throws -> [SRVRecord] {
      guard let resolver else { fatalError("\(self) is inactive.") }

      return try await resolver.querySRV(name: name).map {
        SRVRecord(
          domainName: name,
          ttl: 0,
          data: .init(priority: $0.priority, weight: $0.weight, port: $0.port, hostname: $0.host)
        )
      }
    }
  }

  #if swift(>=6.0)
    extension AsyncDNSResolver: @retroactive @unchecked Sendable {}
  //extension AsyncDNSResolver: @retroactive DNSResolver {}
  #else
    extension AsyncDNSResolver: @unchecked Sendable {}
    extension AsyncDNSResolver: DNSResolver {}
  #endif

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
#endif
