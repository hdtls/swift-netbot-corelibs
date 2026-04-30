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

import Dispatch
import Logging
import NEAddressProcessing
import NIOCore
import NetbotLite
import NetbotLiteData
import _DNSSupport
import _ProfileSupport

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  import NIOConcurrencyHelpers
#else
  import Synchronization
#endif

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@Lockable final public class LocalDNSProxy: Sendable {

  public struct Options: Sendable {
    public let group: any EventLoopGroup
    public let logger: Logger
    public let bindAddress: IPv4Address
    #if compiler(>=6.2)
      public let additionalServers: any Collection<Address> & Sendable
      public let mappings: any Collection<ProtocolDNS.Mapping> & Sendable
    #else
      public let additionalServers: [Address]
      public let mappings: [ProtocolDNS.Mapping]
    #endif
    public let availableIPPool: AvailableIPPool
    public let timeoutInterval: TimeAmount
    public let maxRetryAttempts: Int

    #if compiler(>=6.2)
      public init(
        group: any EventLoopGroup,
        logger: Logger = Logger(label: "dns"),
        bindAddress: IPv4Address,
        additionalServers: any Collection<Address> & Sendable,
        mappings: any Collection<ProtocolDNS.Mapping> & Sendable,
        availableIPPool: AvailableIPPool,
        timeoutInterval: TimeAmount = .seconds(2),
        maxRetryAttempts: Int = 3
      ) {
        self.group = group
        self.logger = logger
        self.bindAddress = bindAddress
        self.additionalServers = additionalServers
        self.mappings = mappings
        self.availableIPPool = availableIPPool
        self.timeoutInterval = timeoutInterval
        self.maxRetryAttempts = maxRetryAttempts
      }
    #else
      public init(
        group: any EventLoopGroup,
        logger: Logger = Logger(label: "dns"),
        bindAddress: IPv4Address,
        additionalServers: [Address],
        mappings: [ProtocolDNS.Mapping],
        availableIPPool: AvailableIPPool,
        timeoutInterval: TimeAmount = .seconds(2),
        maxRetryAttempts: Int = 3
      ) {
        self.group = group
        self.logger = logger
        self.bindAddress = bindAddress
        self.additionalServers = additionalServers
        self.mappings = mappings
        self.availableIPPool = availableIPPool
        self.timeoutInterval = timeoutInterval
        self.maxRetryAttempts = maxRetryAttempts
      }
    #endif
  }

  public var bindAddress: IPv4Address {
    options.bindAddress
  }

  #if compiler(>=6.2)
    public var additionalServers: any Collection<Address> & Sendable {
      options.additionalServers
    }
  #else
    public var additionalServers: [Address] {
      options.additionalServers
    }
  #endif

  public var availableIPPool: AvailableIPPool {
    options.availableIPPool
  }

  var group: any EventLoopGroup { options.group }
  var logger: Logger { options.logger }
  let parser = NLDNSParser()

  let availableAQueries: LRUCache<String, Task<[Expirable<ARecord>], any Error>>
  let disguisedARecords: LRUCache<String, Expirable<ARecord>>
  let availableAAAAQueries: LRUCache<String, Task<[Expirable<AAAARecord>], any Error>>
  let availableSOAQueries: LRUCache<String, Task<[Expirable<SOARecord>], any Error>>
  let availablePTRQueries: LRUCache<String, Task<[Expirable<PTRRecord>], any Error>>

  internal typealias AsyncChannel = NIOAsyncChannel<
    AddressedEnvelope<ByteBuffer>, AddressedEnvelope<ByteBuffer>
  >

  private var queries:
    [SocketAddress: (
      continuation: AsyncStream<Message>.Continuation, queries: [UInt16: EventLoopPromise<Message>]
    )]

  @LockableTracked(accessLevel: .public, accessors: .get)
  public var options: Options

  public init(options: Options) {
    self._options = .init(options)
    self.availableAQueries = .init(capacity: 200)
    self.availableAAAAQueries = .init(capacity: 200)
    self.availableSOAQueries = .init(capacity: 50)
    self.availablePTRQueries = .init(capacity: 200)
    self.disguisedARecords = .init(capacity: 200)
    self._queries = .init([:])
  }

  public convenience init(
    group: any EventLoopGroup = .shared,
    bindAddress: IPv4Address = IPv4Address("198.18.0.2")!,
    additionalServers: [Address] = [],
    availableIPPool: AvailableIPPool = AvailableIPPool(
      bounds: (IPv4Address("198.18.0.2")!, IPv4Address("198.19.255.255")!)
    )
  ) {
    self.init(
      options: .init(
        group: group,
        bindAddress: bindAddress,
        additionalServers: additionalServers,
        mappings: [],
        availableIPPool: availableIPPool
      )
    )
  }

  public func run() async throws {
    Task {
      try await run0()
    }
  }

  public func run0() async throws {}

  public func shutdownGracefully() async throws {
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

  private func startDNSq(server: SocketAddress, transactionID: UInt16) async throws -> (
    promise: EventLoopPromise<Message>,
    continuation: AsyncStream<Message>.Continuation?
  ) {
    if let (continuation, queries) = self._queries.withLock({ $0[server] }) {
      if let promise = queries[transactionID] {
        return (promise, continuation)
      }

      let promise = self.group.any().makePromise(of: Message.self)
      self._queries.withLock {
        $0[server]?.queries[transactionID] = promise
      }
      return (promise, continuation)
    }

    let promise = self.group.any().makePromise(of: Message.self)
    let (stream, continuation) = AsyncStream<Message>.makeStream()
    let query = (promise: promise, continuation: continuation)
    self._queries.withLock {
      $0[server] = (continuation, [transactionID: promise])
    }

    let channel = try await DatagramClientBootstrap(group: group)
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
    // The `additionalServers` may changed, if our dns mappings contains dns server map.
    var additionalServers = options.additionalServers
    var lastError: any Error = DNSError.operationRefused

    // For current version, DNS mapping requires that the query contains
    // only one question.
    if message.questions.count == 1,
      let question = message.questions.first,
      let mapping = self.options.mappings.first(where: { $0.domainName == question.domainName })
    {
      @inline(__always) func response(_ record: any ResourceRecord) -> Message {
        Message(
          headerFields: .init(
            transactionID: message.headerFields.transactionID,
            flags: .init(rawValue: 0x8180),
            qestionCount: UInt16(message.questions.count),
            answerCount: 1,
            authorityCount: 0,
            additionCount: 0
          ),
          questions: message.questions,
          answerRRs: [record],
          authorityRRs: [],
          additionalRRs: []
        )
      }
      switch mapping.strategy {
      case .mapping:
        switch question.queryType {
        case .a:
          if let address = IPv4Address(mapping.value) {
            return response(
              ARecord(
                domainName: question.domainName,
                ttl: 0,
                dataLength: .determined(4),
                data: address
              )
            )
          }
        case .aaaa:
          if let address = IPv6Address(mapping.value) {
            return response(
              AAAARecord(
                domainName: question.domainName,
                ttl: 0,
                dataLength: .determined(16),
                data: address
              )
            )
          }
        default:
          break
        }
      case .cname:
        return response(CNAMERecord(domainName: question.domainName, ttl: 0, data: mapping.value))
      case .dns:
        additionalServers = [Address.hostPort(host: .init(mapping.value), port: 53)]
      }
    }

    for _ in 0..<options.maxRetryAttempts {
      for additionalServer in additionalServers {
        let server = try additionalServer.asAddress()

        do {
          let eventLoop = group.next()

          let query = try await startDNSq(
            server: server,
            transactionID: message.headerFields.transactionID
          )
          let queryPromise = query.promise

          let schedule = eventLoop.scheduleTask(in: options.timeoutInterval) {
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
  func queryDisguisedA(name: String) async throws -> [ARecord] {
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

#if canImport(Network)
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
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
