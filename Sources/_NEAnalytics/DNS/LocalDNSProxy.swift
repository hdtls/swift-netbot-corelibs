//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Dispatch
import Logging
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore
import NIOPosix
import _PrettyDNS

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
actor LocalDNSProxy: PacketHandle {

  private var allocator: ByteBufferAllocator {
    channel!.channel.allocator
  }

  private let parser = PrettyDNSParser()
  private let availableAQueries: LRUCache<String, Task<[Expirable<ARecord>], any Error>>
  private let disguisedARecords: LRUCache<String, Expirable<ARecord>>
  private let availableAAAAQueries: LRUCache<String, Task<[Expirable<AAAARecord>], any Error>>
  private let availableSOAQueries: LRUCache<String, Task<[Expirable<SOARecord>], any Error>>
  private let availablePTRQueries: LRUCache<String, Task<[Expirable<PTRRecord>], any Error>>

  private let bindAddress: String
  private let additionalServers: [Address]
  private let availableIPPool: AvailableIPPool

  private let logger = Logger(label: "dns")

  internal typealias AsyncChannel = NIOAsyncChannel<
    AddressedEnvelope<ByteBuffer>, AddressedEnvelope<ByteBuffer>
  >

  internal var channel: AsyncChannel?
  private var sessions: [UInt16: EventLoopPromise<Message>] = [:]
  private let eventLoopGroup: any EventLoopGroup = NIOPosix.MultiThreadedEventLoopGroup.singleton

  private let queries = AsyncStream.makeStream(of: Message.self)

  init(server: String, additionalServers: [Address], availableIPPool: AvailableIPPool) {
    self.bindAddress = server
    self.additionalServers = additionalServers
    self.availableIPPool = availableIPPool
    self.availableAQueries = .init(capacity: 200)
    self.availableAAAAQueries = .init(capacity: 200)
    self.availableSOAQueries = .init(capacity: 50)
    self.availablePTRQueries = .init(capacity: 200)
    self.disguisedARecords = .init(capacity: 200)
  }

  nonisolated func runIfActive() async throws {
    try await runIfActive0()

    Task {
      // After `runIfActive0() the channel is set
      // and should not be nil, so it's ok unwrapping value.
      try await channel!.executeThenClose { inbound, outbound in

        // We need to specific type of ChildTaskResult to make it compatible with Swift 6.0.
        try await withThrowingTaskGroup(of: Void.self) { g in
          g.addTask { [self] in
            for await query in queries.stream {
              for serverAddress in additionalServers {
                let envelope = try await AddressedEnvelope(
                  remoteAddress: serverAddress.address,
                  data: allocator.buffer(bytes: query.serializedBytes)
                )

                do {
                  try await outbound.write(envelope)
                  break
                } catch {
                  // Failed to write data to remote address, try with next server.
                  continue
                }
              }
            }
          }

          g.addTask { [self] in
            for try await envelop in inbound {
              let message = try parser.parse(envelop.data)

              // It's a DNS response if sessions contains promise for
              // specific transaction ID, otherwise it's a query.
              // For now, we don't support query handle, message will
              // be ignored.
              guard let promise = await sessions[message.headerFields.transactionID] else {
                return
              }
              promise.succeed(message)
            }
          }

          try await g.waitForAll()
        }
      }
    }
  }

  private func runIfActive0() async throws {
    guard channel == nil else { return }

    channel = try await DatagramBootstrap(group: MultiThreadedEventLoopGroup.singleton)
      .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
      .bind(to: .init(ipAddress: "0.0.0.0", port: 0)) { channel in
        channel.eventLoop.makeCompletedFuture {
          try NIOAsyncChannel(
            wrappingChannelSynchronously: channel,
            configuration: .init(
              inboundType: AddressedEnvelope<ByteBuffer>.self,
              outboundType: AddressedEnvelope<ByteBuffer>.self
            )
          )
        }
      }
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

    // Confirm that the packet is send to our fake DNS server.
    guard IPv4Address(bindAddress) == destinationAddress, destinationPort == 53 else {
      return .discarded
    }

    guard let dnsPayload = datagram.payload, !dnsPayload.isEmpty else {
      // If DNS message is missing, we discard this packet.
      return .discarded
    }

    var message = try parser.parse(dnsPayload)

    var msg = "\(packet.sourceAddress) => \(packet.destinationAddress) \(packet.totalLength)"
    logger.debug("\(msg) \(message.formatted())")
    logger.trace("\(msg) \(message.formatted(.detailed))")

    // TODO: Multiple Qestions.
    if let question = message.questions.first {
      switch question.queryType {
      case .a:
        // All communications inside of the domain protocol are carried in the same
        // message format, so we can modify query message to fake response message.
        message.headerFields.flags = .init(
          response: true,
          opcode: .query,
          authoritative: false,
          truncated: false,
          recursionDesired: false,
          recursionAvailable: false,
          authenticatedData: false,
          checkingDisabled: false,
          responseCode: .noError
        )
        message.headerFields.answerCount = 1
        message.headerFields.authorityCount = 0
        message.headerFields.additionCount = 0
        message.answerRRs = try await queryDisguisedA(name: question.domainName)
        message.authorityRRs = []
        message.additionalRRs = []
      // TODO: IPv6 Support
      //    case .aaaa:
      default:
        message = try await query(msg: message)
      }
    } else {
      message = try await query(msg: message)
    }

    // Revese source and destination address.
    datagram.destinationPort = datagram.sourcePort
    datagram.sourcePort = destinationPort
    datagram.payload = try allocator.buffer(bytes: message.serializedBytes)
    datagram.pseudoFields.destinationAddress = datagram.pseudoFields.sourceAddress
    datagram.pseudoFields.sourceAddress = destinationAddress
    datagram.pseudoFields.dataLength = datagram.totalLength

    packet.differentiatedServicesCodePoint = 0
    packet.explicitCongestionNotification = 0
    packet.identification = .random(in: 0xC000 ... .max)
    packet.flags = 0
    packet.fragmentOffset = 0
    packet.timeToLive = 64
    packet.destinationAddress = packet.sourceAddress
    packet.sourceAddress = destinationAddress
    packet.options = nil
    packet.payload = datagram.data

    msg = "\(packet.sourceAddress) => \(packet.destinationAddress) \(packet.totalLength)"
    logger.debug("\(msg) \(message.formatted())")
    logger.trace("\(msg) \(message.formatted(.detailed))")

    return .handled(.v4(packet))
  }

  // Returns disguised records contains one reserved IPv4 address.
  private func queryDisguisedA(name: String) async throws -> [ARecord] {
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
        ARecord(domainName: name, ttl: 300, data: availableIPPool.loadThenWrappingIncrement())
      )
    }

    disguisedARecords.setValue(value, forKey: name)
    return [value.record]
  }

  func query(msg message: Message) async throws -> Message {
    guard channel != nil else {
      return Message(
        headerFields: .init(
          transactionID: message.headerFields.transactionID,
          flags: .init(rawValue: 0x8000),
          qestionCount: 1,
          answerCount: 0,
          authorityCount: 0,
          additionCount: 0
        ),
        questions: message.questions,
        answerRRs: [],
        authorityRRs: [],
        additionalRRs: []
      )
    }
    let promise = eventLoopGroup.next().makePromise(of: Message.self)
    sessions[message.headerFields.transactionID] = promise
    queries.continuation.yield(message)
    defer {
      sessions.removeValue(forKey: message.headerFields.transactionID)
    }
    return try await promise.futureResult.get()
  }

  func query(name: String, qt: QTYPE) async throws -> Message {
    let message = Message(
      headerFields: .init(
        transactionID: UInt16.random(in: 0...UInt16.max),
        flags: .init(rawValue: 0x8181),
        qestionCount: 1,
        answerCount: 0,
        authorityCount: 0,
        additionCount: 0
      ),
      questions: [Question(domainName: name, queryType: qt)],
      answerRRs: [],
      authorityRRs: [],
      additionalRRs: []
    )
    return try await query(msg: message)
  }
}

extension LocalDNSProxy: _PrettyDNS.Resolver {

  func queryA(name: String) async throws -> [ARecord] {
    guard let task = availableAQueries.value(forKey: name) else {
      return try await queryA0(name: name).map(\.record)
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

    return try await queryA0(name: name).map(\.record)
  }

  private func queryA0(name: String) async throws -> [Expirable<ARecord>] {
    guard channel != nil else { return [] }

    let task = Task<[Expirable<ARecord>], any Error> {
      try await query(name: name, qt: .a).answerRRs.lazy.compactMap { $0 as? ARecord }.map {
        Expirable($0)
      }
    }
    availableAQueries.setValue(task, forKey: name)
    return try await task.value
  }

  func queryAAAA(name: String) async throws -> [AAAARecord] {
    guard let task = availableAAAAQueries.value(forKey: name) else {
      return try await self.queryAAAA0(name: name).map(\.record)
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
    return try await self.queryAAAA0(name: name).map(\.record)
  }

  private func queryAAAA0(name: String) async throws -> [Expirable<AAAARecord>] {
    guard channel != nil else { return [] }

    let task = Task<[Expirable<AAAARecord>], any Error> {
      try await query(name: name, qt: .aaaa).answerRRs.lazy.compactMap { $0 as? AAAARecord }.map {
        Expirable($0)
      }
    }
    availableAAAAQueries.setValue(task, forKey: name)
    return try await task.value
  }

  func queryNS(name: String) async throws -> [NSRecord] {
    try await query(name: name, qt: .ns).answerRRs.compactMap { $0 as? NSRecord }
  }

  func queryCNAME(name: String) async throws -> [CNAMERecord] {
    try await query(name: name, qt: .cname).answerRRs.compactMap { $0 as? CNAMERecord }
  }

  func querySOA(name: String) async throws -> [SOARecord] {
    try await query(name: name, qt: .soa).answerRRs.compactMap { $0 as? SOARecord }
  }

  func queryPTR(name: String) async throws -> [PTRRecord] {
    try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
  }

  func queryMX(name: String) async throws -> [MXRecord] {
    try await query(name: name, qt: .mx).answerRRs.compactMap { $0 as? MXRecord }
  }

  func queryTXT(name: String) async throws -> [TXTRecord] {
    try await query(name: name, qt: .txt).answerRRs.compactMap { $0 as? TXTRecord }
  }

  func querySRV(name: String) async throws -> [SRVRecord] {
    try await query(name: name, qt: .srv).answerRRs.compactMap { $0 as? SRVRecord }
  }
}

extension LocalDNSProxy: @preconcurrency Anlzr.Resolver, @preconcurrency NIOPosix.Resolver {

  func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[SocketAddress]> {
    eventLoopGroup.next().makeFutureWithTask {
      try await self.queryA(name: host).map {
        try SocketAddress(ipAddress: "\($0.data)", port: port)
      }
    }
  }

  func initiateAAAAQuery(host: String, port: Int) -> EventLoopFuture<[SocketAddress]> {
    eventLoopGroup.next().makeFutureWithTask {
      try await self.queryAAAA(name: host).map {
        try SocketAddress(ipAddress: "\($0.data)", port: port)
      }
    }
  }

  func cancelQueries() {}
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
