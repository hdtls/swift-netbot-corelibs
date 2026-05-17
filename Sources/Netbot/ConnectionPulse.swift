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
import NetbotLite
import NetbotLiteData
import SynchronizationExtras

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Network)
  import Network
#else
  import NIOExtras
  import NIOHTTP1
  import NIOPosix
  import NIOWebSocket
#endif

#if !canImport(Darwin) || !NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  import Synchronization
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@Lockable final class ConnectionPulse: ConnectionPublisher, Sendable {

  private let group: any EventLoopGroup
  private let address: Address
  #if canImport(Network)
    private var outboundStreams: [ObjectIdentifier: NWConnection]
    private let closePromise: EventLoopPromise<Void>
    private var listener: NWListener?
  #else
    private var outboundStreams: [ObjectIdentifier: AsyncStream<ByteBuffer>.Continuation]
    private let quiescing: ServerQuiescingHelper
  #endif
  private let jsonEncoder = JSONEncoder()

  private var connections: [UInt64: Connection]

  init(group: any EventLoopGroup, address: Address) {
    self.group = group
    self.address = address
    self._outboundStreams = .init([:])
    #if canImport(Network)
      self.closePromise = group.next().makePromise()
      self._listener = .init(nil)
    #else
      self.quiescing = ServerQuiescingHelper(group: group)
    #endif
    self._connections = .init([:])
  }

  func run() async throws {
    // FIXME: [#NoUseUnstructuredThrowingTask]
    _ = Task {
      try await run0()
    }
  }

  func run0() async throws {
    #if canImport(Network)
      let parameters = NWParameters.tcp
      parameters.requiredLocalEndpoint = try address.asEndpoint()
      let options = NWProtocolWebSocket.Options()
      options.autoReplyPing = true
      options.setClientRequestHandler(.global()) { _, additionalHeaders in
        self.authorize(additionalHeaders)
      }
      parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)

      listener = try NWListener(using: parameters)
      listener?.stateUpdateHandler = { [self] in
        switch $0 {
        case .setup, .ready:
          break
        case .waiting(let error):
          closePromise.fail(error)
        case .failed(let error):
          closePromise.fail(error)
        case .cancelled:
          closePromise.succeed()
        @unknown default:
          break
        }
      }
      listener?.newConnectionHandler = { connection in
        connection.stateUpdateHandler = {
          switch $0 {
          case .setup, .waiting, .preparing:
            break
          case .ready:
            self._outboundStreams.withLock {
              $0[ObjectIdentifier(connection)] = connection
            }
          case .failed, .cancelled:
            self._outboundStreams.withLock {
              _ = $0.removeValue(forKey: ObjectIdentifier(connection))
            }
          @unknown default:
            break
          }
        }
        connection.start(queue: .global())
      }
      listener?.start(queue: .global())
      try await closePromise.futureResult.get()
    #else
      let channel = try await ServerBootstrap(group: group)
        .serverChannelInitializer { channel in
          channel.eventLoop.makeCompletedFuture {
            let handler = self.quiescing.makeServerChannelHandler(channel: channel)
            try channel.pipeline.syncOperations.addHandler(handler)
          }
        }
        .bind(to: address.asAddress()) { channel in
          let ws = NIOTypedWebSocketServerUpgrader(
            shouldUpgrade: { channel, head in
              channel.eventLoop
                .makeSucceededFuture(
                  self.authorize(Array(head.headers))
                )
            },
            upgradePipelineHandler: { channel, _ in
              channel.eventLoop.makeCompletedFuture {
                try channel.pipeline.syncOperations.addHandlers([
                  NIOWebSocketFrameAggregator(
                    minNonFinalFragmentSize: 1024,
                    maxAccumulatedFrameCount: 16,
                    maxAccumulatedFrameSize: 1 << 20
                  ),
                  WebSocketAutoReply(),
                  WebSocketFrameToByteBufferCodec(),
                ])
              }
              .flatMapThrowing {
                try NIOAsyncChannel<ByteBuffer, ByteBuffer>(
                  wrappingChannelSynchronously: channel)
              }
            }
          )
          return channel.pipeline
            .configureUpgradableHTTPServerPipeline(
              configuration: .init(
                upgradeConfiguration: .init(upgraders: [ws]) { channel in
                  channel.eventLoop.makeFailedFuture(AnalyzeError.connectionRefused)
                }
              )
            )
        }

      try await withThrowingDiscardingTaskGroup { g in
        try await channel.executeThenClose { inbound in
          for try await negotiationResult in inbound {
            g.addTask {
              let childChannel = try await negotiationResult.get()

              let key = ObjectIdentifier(childChannel.channel)
              let (stream, continuation) = AsyncStream.makeStream(of: ByteBuffer.self)
              self._outboundStreams.withLock {
                $0[key] = continuation
              }

              try await childChannel.executeThenClose { _, outbound in
                try await withThrowingTaskGroup(of: Void.self) { g in
                  g.addTask {
                    for try await frame in stream {
                      try? await outbound.write(frame)
                    }
                  }

                  try await g.next()
                  g.cancelAll()
                }
              }

              self._outboundStreams.withLock {
                _ = $0.removeValue(forKey: key)
              }
            }
          }
        }
      }
    #endif
  }

  #if canImport(Network)
    private func authorize(_ httpFields: [(name: String, value: String)])
      -> NWProtocolWebSocket.Response
    {
      return .init(status: .accept, subprotocol: nil)
    }
  #else
    private func authorize(_ httpFields: [(name: String, value: String)]) -> HTTPHeaders {
      return .init()
    }
  #endif

  func shutdownGracefully() async throws {
    self._outboundStreams.withLock { outboundStreams in
      for outboundStream in outboundStreams {
        #if canImport(Network)
          outboundStream.value.cancel()
        #else
          outboundStream.value.finish()
        #endif
      }
      outboundStreams.removeAll()
    }

    let promise = group.next().makePromise(of: Void.self)
    #if canImport(Network)
      promise.futureResult.cascade(to: self.closePromise)
      self.listener?.cancel()
      self.listener = nil
      self.closePromise.succeed()
    #else
      quiescing.initiateShutdown(promise: promise)
    #endif
    try await promise.futureResult.get()
  }

  func send(_ conn: Connection) async {
    self._connections.withLock {
      $0[conn.taskIdentifier] = conn

      guard !outboundStreams.isEmpty else {
        return
      }

      guard let data = try? jsonEncoder.encode(Array($0.values)) else {
        return
      }
      $0.removeAll()

      for outboundStream in outboundStreams {
        #if canImport(Network)
          outboundStream.value
            .send(
              content: data,
              contentContext: .init(
                identifier: "connections",
                metadata: [NWProtocolWebSocket.Metadata(opcode: .binary)]
              ),
              completion: .contentProcessed { _ in }
            )
        #else
          outboundStream.value.yield(ByteBuffer(bytes: data))
        #endif
      }
    }
  }
}
