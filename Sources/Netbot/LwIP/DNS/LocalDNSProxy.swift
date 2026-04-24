// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Atomics
import Dispatch
import Logging
import NEAddressProcessing
import NIOCore
import NetbotLite
import NetbotLiteData
import _DNSSupport

#if canImport(Darwin) && NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  import NIOConcurrencyHelpers
#else
  import Synchronization
#endif

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@Lockable final public class LocalDNSProxy: Sendable {

  private let parser = NLDNSParser()
  private let availableAQueries: LRUCache<String, Task<[Expirable<ARecord>], any Error>>
  private let disguisedARecords: LRUCache<String, Expirable<ARecord>>
  private let availableAAAAQueries: LRUCache<String, Task<[Expirable<AAAARecord>], any Error>>
  private let availableSOAQueries: LRUCache<String, Task<[Expirable<SOARecord>], any Error>>
  private let availablePTRQueries: LRUCache<String, Task<[Expirable<PTRRecord>], any Error>>

  public var packetFlow: (any PacketTunnelFlow)?
  public var bindAddress: IPv4Address
  public var additionalServers: [Address]

  @LockableTracked(accessLevel: .package)
  public var availableIPPool: AvailableIPPool

  private let logger = Logger(label: "dns")

  internal typealias AsyncChannel = NIOAsyncChannel<
    AddressedEnvelope<ByteBuffer>, AddressedEnvelope<ByteBuffer>
  >

  private let eventLoopGroup: any EventLoopGroup

  private var queries:
    [SocketAddress: (
      continuation: AsyncStream<Message>.Continuation, queries: [UInt16: EventLoopPromise<Message>]
    )]

  public init(
    group: any EventLoopGroup = .shared,
    bindAddress: IPv4Address = IPv4Address("198.18.0.2")!,
    additionalServers: [Address] = [],
    availableIPPool: AvailableIPPool = AvailableIPPool(
      bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
    )
  ) {
    self.eventLoopGroup = group
    self.availableAQueries = .init(capacity: 200)
    self.availableAAAAQueries = .init(capacity: 200)
    self.availableSOAQueries = .init(capacity: 50)
    self.availablePTRQueries = .init(capacity: 200)
    self.disguisedARecords = .init(capacity: 200)
    self._packetFlow = .init(nil)
    self._bindAddress = .init(bindAddress)
    self._additionalServers = .init(additionalServers)
    self._availableIPPool = .init(availableIPPool)
    self._queries = .init([:])
  }

  public func close() async throws {
    self._queries.withLock {
      for queries in $0.values {
        for query in queries.queries {
          // Fail all in-progress queries with CancellationError.
          query.value.fail(ChannelError.ioOnClosedChannel)
        }

        // Finish all in-progress query stream.
        queries.continuation.finish()
      }

      $0.removeAll()
    }
  }

  public func close(promise: EventLoopPromise<Void>?) {
    eventLoopGroup.any().makeFutureWithTask {
      try await self.close()
    }
    .cascade(to: promise)
  }

  private func startDNSq(server: SocketAddress, transactionID: UInt16) async throws -> (
    promise: EventLoopPromise<Message>,
    continuation: AsyncStream<Message>.Continuation?
  ) {
    if let (continuation, queries) = self._queries.withLock({ $0[server] }) {
      if let promise = queries[transactionID] {
        return (promise, continuation)
      }

      let promise = self.eventLoopGroup.any().makePromise(of: Message.self)
      self._queries.withLock {
        $0[server]?.queries[transactionID] = promise
      }
      return (promise, continuation)
    }

    let promise = self.eventLoopGroup.any().makePromise(of: Message.self)
    let (stream, continuation) = AsyncStream<Message>.makeStream()
    let query = (promise: promise, continuation: continuation)
    self._queries.withLock {
      $0[server] = (continuation, [transactionID: promise])
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

    channel.channel.closeFuture.whenComplete { _ in
      self._queries.withLock {
        guard let (continuation, queries) = $0.removeValue(forKey: server) else {
          return
        }

        continuation.finish()
        for promise in queries.values {
          promise.fail(ChannelError.ioOnClosedChannel)
        }
      }
    }

    Task.detached {
      try await channel.executeThenClose { inbound, outbound in

        // We need to specific type of ChildTaskResult to make it compatible with Swift 6.0.
        try await withThrowingTaskGroup(of: Void.self) { g in
          g.addTask {
            for try await query in stream {
              do {
                let envelope = try AddressedEnvelope(
                  remoteAddress: server,
                  data: channel.channel.allocator.buffer(bytes: query.serializedBytes)
                )
                try await outbound.write(envelope)
              } catch {
                // Notify that we are failed to write dns query message to the server.
                self._queries.withLock {
                  let promise = $0[server]?.queries[query.headerFields.transactionID]
                  promise?.fail(error)
                }
              }
            }
          }

          g.addTask {
            for try await envelop in inbound {
              do {
                // Channel read should not be interrupted.
                let message = try self.parser.parse(envelop.data)

                // Notify that we have received dns response if needed.
                self._queries.withLock {
                  let promise = $0[server]?.queries[message.headerFields.transactionID]
                  promise?.succeed(message)
                }
              } catch {
                // Notify that we received data but can't decode as DNS reponse message.
                // promise.fail(error)
              }
            }
          }

          try await g.waitForAll()
        }
      }
    }

    return query
  }

  func query(msg message: Message) async throws -> Message {
    var lastError: any Error = DNSError.operationRefused

    let timeAmount = TimeAmount.seconds(2)
    let maxRetryAttempts = 3

    for additionalServer in additionalServers {
      for _ in 0..<maxRetryAttempts {
        let server = try additionalServer.asAddress()

        do {
          let eventLoop = eventLoopGroup.next()

          let query = try await startDNSq(
            server: server,
            transactionID: message.headerFields.transactionID
          )
          let queryPromise = query.promise

          let schedule = eventLoop.scheduleTask(in: timeAmount) {
            queryPromise.fail(DNSError.timeout)
          }

          query.continuation?.yield(message)

          let result = try await queryPromise.futureResult.get()

          // Cancel timeout task once we have received dns response.
          schedule.cancel()

          return result
        } catch {
          self._queries.withLock {
            let promise = $0[server]?.queries.removeValue(
              forKey: message.headerFields.transactionID)
            promise?.fail(error)
          }

          lastError = error
          continue
        }
      }
    }

    throw lastError
  }

  func query(name: String, qt: QTYPE) async throws -> Message {
    let message = Message(
      headerFields: .init(
        transactionID: UInt16.random(in: 0...UInt16.max),
        flags: .init(rawValue: 0x0100),
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

  // Returns disguised records contains a reserved IPv4 address.
  private func queryDisguisedA(name: String) async throws -> [ARecord] {
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
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension LocalDNSProxy: PacketHandleProtocol {

  func run() async throws {}

  func handleInput(_ packetObject: NEPacket) async throws -> PacketHandleResult {
    assert(packetFlow != nil, "LocalDNSProxy.packetFlow is required to process NEPacket.")

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
    guard bindAddress == destinationAddress, destinationPort == 53 else {
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

    _ = packetFlow?.writePacketObjects([packetObject])
    return .handled
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension LocalDNSProxy: _DNSSupport.Resolver {

  public func queryA(name: String) async throws -> [ARecord] {
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

  public func queryAAAA(name: String) async throws -> [AAAARecord] {
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

  public func queryNS(name: String) async throws -> [NSRecord] {
    try await query(name: name, qt: .ns).answerRRs.compactMap { $0 as? NSRecord }
  }

  public func queryCNAME(name: String) async throws -> [CNAMERecord] {
    try await query(name: name, qt: .cname).answerRRs.compactMap { $0 as? CNAMERecord }
  }

  public func querySOA(name: String) async throws -> [SOARecord] {
    try await query(name: name, qt: .soa).answerRRs.compactMap { $0 as? SOARecord }
  }

  public func queryPTR(name: String) async throws -> [PTRRecord] {
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

  public func queryMX(name: String) async throws -> [MXRecord] {
    try await query(name: name, qt: .mx).answerRRs.compactMap { $0 as? MXRecord }
  }

  public func queryTXT(name: String) async throws -> [TXTRecord] {
    try await query(name: name, qt: .txt).answerRRs.compactMap { $0 as? TXTRecord }
  }

  public func querySRV(name: String) async throws -> [SRVRecord] {
    try await query(name: name, qt: .srv).answerRRs.compactMap { $0 as? SRVRecord }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension LocalDNSProxy: NetbotLite.Resolver {

  public func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[SocketAddress]> {
    eventLoopGroup.next().makeFutureWithTask {
      try await self.queryA(name: host).map {
        try SocketAddress(ipAddress: "\($0.data)", port: port)
      }
    }
  }

  public func initiateAAAAQuery(host: String, port: Int) -> EventLoopFuture<[SocketAddress]> {
    eventLoopGroup.next().makeFutureWithTask {
      try await self.queryAAAA(name: host).map {
        try SocketAddress(ipAddress: "\($0.data)", port: port)
      }
    }
  }

  public func cancelQueries() {}
}

#if !canImport(Network)
  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension LocalDNSProxy: NIOPosix.Resolver {}
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
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
  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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
