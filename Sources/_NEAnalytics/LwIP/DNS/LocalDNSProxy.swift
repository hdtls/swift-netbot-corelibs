//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Atomics
import Dispatch
import Logging
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore
import _PrettyDNS

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
actor LocalDNSProxy: PacketHandleProtocol {

  private nonisolated let parser = PrettyDNSParser()
  private nonisolated let availableAQueries: LRUCache<String, Task<[Expirable<ARecord>], any Error>>
  private nonisolated let disguisedARecords: LRUCache<String, Expirable<ARecord>>
  private nonisolated let availableAAAAQueries:
    LRUCache<String, Task<[Expirable<AAAARecord>], any Error>>
  private nonisolated let availableSOAQueries:
    LRUCache<String, Task<[Expirable<SOARecord>], any Error>>
  private nonisolated let availablePTRQueries:
    LRUCache<String, Task<[Expirable<PTRRecord>], any Error>>

  internal nonisolated let packetFlow: any PacketTunnelFlow
  private nonisolated let bindAddress: String
  private nonisolated let additionalServers: [Address]
  internal nonisolated let availableIPPool: AvailableIPPool

  private nonisolated let logger = Logger(label: "dns")

  internal typealias AsyncChannel = NIOAsyncChannel<
    AddressedEnvelope<ByteBuffer>, AddressedEnvelope<ByteBuffer>
  >

  private var sessions = [UInt16: EventLoopPromise<Message>]()
  private nonisolated let eventLoopGroup: any EventLoopGroup

  private var queries:
    [SocketAddress: [UInt16: (
      stream: AsyncStream<Message>, continuation: AsyncStream<Message>.Continuation
    )]]

  init(
    group: MultiThreadedEventLoopGroup = .shared,
    packetFlow: any PacketTunnelFlow,
    server: String,
    additionalServers: [Address],
    availableIPPool: AvailableIPPool
  ) {
    self.eventLoopGroup = group
    self.packetFlow = packetFlow
    self.bindAddress = server
    self.additionalServers = additionalServers
    self.availableIPPool = availableIPPool
    self.availableAQueries = .init(capacity: 200)
    self.availableAAAAQueries = .init(capacity: 200)
    self.availableSOAQueries = .init(capacity: 50)
    self.availablePTRQueries = .init(capacity: 200)
    self.disguisedARecords = .init(capacity: 200)
    self.queries = [:]
  }

  nonisolated func runIfActive() async throws {}

  func close() async throws {
    for queries in self.queries.values {
      for query in queries.values {
        query.continuation.finish()
      }
    }
    for promise in sessions.values {
      promise.fail(CancellationError())
    }
  }

  nonisolated func close(promise: EventLoopPromise<Void>?) {
    eventLoopGroup.next().makeFutureWithTask {
      try await self.close()
    }
    .cascade(to: promise)
  }

  private func startDNSq(server: SocketAddress, transactionID: UInt16) async throws -> (
    stream: AsyncStream<Message>, continuation: AsyncStream<Message>.Continuation
  ) {
    if let queries = queries[server], let query = queries[transactionID] {
      // We have already verified that queries non-nil here, so force unwrap is safe.
      return query
    }

    let channel = try await DatagramClientBootstrap(group: eventLoopGroup)
      .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
      .connect(to: server) { channel in
        #if canImport(Network)
          return channel.pipeline.addHandler(AddressedEnvelopeSuite())
            .flatMapThrowing {
              try NIOAsyncChannel(
                wrappingChannelSynchronously: channel,
                configuration: .init(
                  inboundType: AddressedEnvelope<ByteBuffer>.self,
                  outboundType: AddressedEnvelope<ByteBuffer>.self
                )
              )
            }
        #else
          channel.eventLoop.makeCompletedFuture {
            try NIOAsyncChannel(
              wrappingChannelSynchronously: channel,
              configuration: .init(
                inboundType: AddressedEnvelope<ByteBuffer>.self,
                outboundType: AddressedEnvelope<ByteBuffer>.self
              )
            )
          }
        #endif
      }

    let query = AsyncStream<Message>.makeStream()
    query.continuation.onTermination = { _ in
      channel.channel.close(promise: nil)
    }
    var q = self.queries[server] ?? [:]
    q[transactionID] = query
    self.queries[server] = q

    Task(priority: .background) {
      do {
        try await channel.executeThenClose { inbound, outbound in

          // We need to specific type of ChildTaskResult to make it compatible with Swift 6.0.
          try await withThrowingTaskGroup(of: Void.self) { g in
            g.addTask {
              for try await query in query.stream {
                do {
                  let envelope = try AddressedEnvelope(
                    remoteAddress: server,
                    data: channel.channel.allocator.buffer(bytes: query.serializedBytes)
                  )
                  try await outbound.write(envelope)
                } catch {
                  // Failed to write data to remote address, try with next server.
                  let promise = await self.dnsqPromise(
                    transactionID: query.headerFields.transactionID,
                    loadIfNeeded: false
                  )
                  if let promise {
                    promise.fail(error)
                  }

                  throw error
                }
              }
            }

            g.addTask { [self] in
              for try await envelop in inbound {
                // Channel read should not be interrupted.
                let message = try parser.parse(envelop.data)

                // It's a DNS response if sessions contains promise for
                // specific transaction ID, otherwise it's a query.
                // For now, we don't support query handle, message will
                // be ignored.
                let promise = await dnsqPromise(
                  transactionID: message.headerFields.transactionID,
                  loadIfNeeded: false
                )
                if let promise {
                  promise.succeed(message)
                }

                #if !canImport(Network)
                  throw ChannelError.eof
                #endif
              }
            }

            try await g.waitForAll()
          }
        }
      } catch {
        self.offloadDNSq(server: server, transactionID: transactionID)
      }
    }

    return query
  }

  private func dnsqPromise(transactionID: UInt16, loadIfNeeded: Bool = true) -> EventLoopPromise<
    Message
  >? {
    guard loadIfNeeded else { return sessions[transactionID] }

    let promise = eventLoopGroup.next().makePromise(of: Message.self)
    sessions[transactionID] = promise
    return promise
  }

  private func offloadDNSq(server: SocketAddress, transactionID: UInt16) {
    var queries = queries[server]
    queries?.removeValue(forKey: transactionID)
    self.queries[server] = queries
    self.sessions.removeValue(forKey: transactionID)
  }

  nonisolated func handleInput(_ packetObject: NEPacket) async throws -> PacketHandleResult {
    // Make it mutable, so we don't need alloc new packet for response.
    guard case .v4(var iphdr) = packetObject.headerFields else {
      // IPv4 only now.
      return .discarded
    }

    // Large DNS query over TCP is not supported yet.
    guard iphdr.protocol == .udp else {
      return .discarded
    }

    // Make sure the packet contains transport layer data.
    guard packetObject.payload.count >= MemoryLayout<UInt16>.size * 4 else {
      return .discarded
    }

    // Make it mutable, so we don't need alloc another datagram for response.
    var datagram = Datagram(
      data: packetObject.payload,
      pseudoFields: .init(
        sourceAddress: iphdr.sourceAddress,
        destinationAddress: iphdr.destinationAddress,
        protocol: iphdr.protocol,
        dataLength: UInt16(packetObject.payload.count)
      )
    )

    // Store address to make response by exchange source/destination address and port.
    let destinationAddress = iphdr.destinationAddress
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

    var msg = "\(iphdr.sourceAddress) => \(iphdr.destinationAddress) \(iphdr.totalLength)"
    logger.info("\(msg) \(message.formatted())")
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
        message.answerRRs = try await queryDisguisedA(name: question.domainName)
        message.authorityRRs = []
        message.additionalRRs = []
        message.headerFields.answerCount = UInt16(message.answerRRs.count)
        message.headerFields.authorityCount = UInt16(message.authorityRRs.count)
        message.headerFields.additionCount = UInt16(message.additionalRRs.count)
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
    datagram.payload = try ByteBuffer(bytes: message.serializedBytes)
    datagram.pseudoFields.destinationAddress = datagram.pseudoFields.sourceAddress
    datagram.pseudoFields.sourceAddress = destinationAddress
    datagram.pseudoFields.dataLength = datagram.totalLength

    iphdr.differentiatedServicesCodePoint = 0
    iphdr.explicitCongestionNotification = 0
    iphdr.identification = .random(in: 0xC000 ... .max)
    iphdr.flags = 0
    iphdr.fragmentOffset = 0
    iphdr.timeToLive = 64
    iphdr.destinationAddress = iphdr.sourceAddress
    iphdr.sourceAddress = destinationAddress
    iphdr.options = nil
    iphdr.totalLength = UInt16(iphdr.data.count + datagram.data.count)

    msg = "\(iphdr.sourceAddress) => \(iphdr.destinationAddress) \(iphdr.totalLength)"
    logger.info("\(msg) \(message.formatted())")
    logger.trace("\(msg) \(message.formatted(.detailed))")

    var data = iphdr.data
    data.append(contentsOf: datagram.data)
    guard let packetObject = NEPacket(data: data, protocolFamily: iphdr.protocolFamily) else {
      return .discarded
    }

    _ = packetFlow.writePacketObjects([packetObject])
    return .handled
  }

  // Returns disguised records contains a reserved IPv4 address.
  nonisolated private func queryDisguisedA(name: String) async throws -> [ARecord] {
    var value: Expirable<ARecord>
    if let stored = disguisedARecords.value(forKey: name) {
      value = stored
      value.time = .now()
    } else {
      value = Expirable(
        ARecord(domainName: name, ttl: 300, data: availableIPPool.loadThenWrappingIncrement())
      )
      // Query A records for use later
      Task.detached(priority: .background) {
        _ = try await self.queryA(name: name)
      }
    }

    disguisedARecords.setValue(value, forKey: name)
    return [value.record]
  }

  nonisolated func query(msg message: Message) async throws -> Message {
    var lastError: any Error = ChannelError.operationUnsupported

    let timeAmount = TimeAmount.seconds(2)
    let maxRetryAttempts = 3

    for additionalServer in additionalServers {
      let server = try additionalServer.address

      for _ in 0..<maxRetryAttempts {
        do {
          let eventLoop = eventLoopGroup.next()

          let queries = try await startDNSq(
            server: server,
            transactionID: message.headerFields.transactionID
          )
          let queryPromise = await dnsqPromise(transactionID: message.headerFields.transactionID)!

          let schedule = eventLoop.scheduleTask(in: timeAmount) {
            struct DNSQueryTimeoutError: Error {}
            queryPromise.fail(DNSQueryTimeoutError())
          }

          // TODO: Handle yield failure.
          queries.continuation.yield(message)

          let result = try await queryPromise.futureResult.get()
          schedule.cancel()
          await offloadDNSq(server: server, transactionID: message.headerFields.transactionID)
          return result
        } catch {
          await offloadDNSq(server: server, transactionID: message.headerFields.transactionID)
          lastError = error
          continue
        }
      }
    }

    throw lastError
  }

  nonisolated func query(name: String, qt: QTYPE) async throws -> Message {
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

  nonisolated func queryA(name: String) async throws -> [ARecord] {
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

  nonisolated private func queryA0(name: String) async throws -> [Expirable<ARecord>] {
    let task = Task<[Expirable<ARecord>], any Error>.detached {
      try await self.query(name: name, qt: .a).answerRRs.lazy.compactMap { $0 as? ARecord }.map {
        Expirable($0)
      }
    }
    availableAQueries.setValue(task, forKey: name)

    do {
      return try await task.value
    } catch {
      // If task failed we should remove it from cache.
      availableAQueries.removeValue(forKey: name)
      throw error
    }
  }

  nonisolated func queryAAAA(name: String) async throws -> [AAAARecord] {
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

  nonisolated private func queryAAAA0(name: String) async throws -> [Expirable<AAAARecord>] {
    let task = Task<[Expirable<AAAARecord>], any Error>.detached {
      try await self.query(name: name, qt: .aaaa).answerRRs.lazy.compactMap { $0 as? AAAARecord }
        .map {
          Expirable($0)
        }
    }
    availableAAAAQueries.setValue(task, forKey: name)

    do {
      return try await task.value
    } catch {
      // If task failed we should remove it from cache.
      availableAAAAQueries.removeValue(forKey: name)
      throw error
    }
  }

  nonisolated func queryNS(name: String) async throws -> [NSRecord] {
    try await query(name: name, qt: .ns).answerRRs.compactMap { $0 as? NSRecord }
  }

  nonisolated func queryCNAME(name: String) async throws -> [CNAMERecord] {
    try await query(name: name, qt: .cname).answerRRs.compactMap { $0 as? CNAMERecord }
  }

  nonisolated func querySOA(name: String) async throws -> [SOARecord] {
    try await query(name: name, qt: .soa).answerRRs.compactMap { $0 as? SOARecord }
  }

  nonisolated func queryPTR(name: String) async throws -> [PTRRecord] {
    // Check to avoid query PTR records for disguised address.
    let v4 = ".in-addr.arpa"
    guard name.hasSuffix(v4) else {
      return try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
    }
    let prefix = name[..<name.index(name.startIndex, offsetBy: name.count - v4.count)]
    let ipaddr = prefix.split(separator: ".").reversed().joined(separator: ".")
    guard let address = IPv4Address(ipaddr) else {
      return try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
    }

    guard availableIPPool.contains(address) else {
      return try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
    }
    guard let entry = disguisedARecords.first(where: { $0.1.record.data == address }) else {
      return []
    }
    return [PTRRecord(domainName: name, ttl: entry.value.record.ttl, data: entry.key)]
  }

  nonisolated func queryMX(name: String) async throws -> [MXRecord] {
    try await query(name: name, qt: .mx).answerRRs.compactMap { $0 as? MXRecord }
  }

  nonisolated func queryTXT(name: String) async throws -> [TXTRecord] {
    try await query(name: name, qt: .txt).answerRRs.compactMap { $0 as? TXTRecord }
  }

  nonisolated func querySRV(name: String) async throws -> [SRVRecord] {
    try await query(name: name, qt: .srv).answerRRs.compactMap { $0 as? SRVRecord }
  }
}

extension LocalDNSProxy: @preconcurrency Anlzr.Resolver {

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

#if !canImport(Network)
  extension LocalDNSProxy: @preconcurrency NIOPosix.Resolver {}
#endif

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

#if canImport(Network)
  final private class AddressedEnvelopeSuite: ChannelDuplexHandler, Sendable {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = AddressedEnvelope<ByteBuffer>
    typealias OutboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundOut = ByteBuffer

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
      let data = unwrapInboundIn(data)
      guard let remoteAddress = context.remoteAddress else {
        return
      }
      let envelope = AddressedEnvelope(remoteAddress: remoteAddress, data: data)
      context.fireChannelRead(wrapInboundOut(envelope))
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
      let envelope = unwrapOutboundIn(data)
      context.write(wrapOutboundOut(envelope.data), promise: promise)
    }
  }
#endif
