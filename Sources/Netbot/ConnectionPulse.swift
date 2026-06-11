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
import Synchronization
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

@available(SwiftStdlib 6.0, *)
@Lockable final class ConnectionPulse: ConnectionPublisher, Sendable {

  private let group: any EventLoopGroup
  private let address: Address
  var localAddress: Address? = nil

  #if canImport(Network)
    private var outboundStreams: [ObjectIdentifier: NWConnection] = [:]
    private let closePromise: EventLoopPromise<Void>
    private var listener: NWListener? = nil
  #else
    private var outboundStreams: [ObjectIdentifier: AsyncStream<ByteBuffer>.Continuation] = [:]
    private let quiescing: ServerQuiescingHelper
  #endif
  private let coder = JSONEncoder()

  private var requestTaskMap: [UInt64: Connection] = [:]

  init(group: any EventLoopGroup, address: Address) {
    self.group = group
    self.address = address
    #if canImport(Network)
      self.closePromise = group.next().makePromise()
    #else
      self.quiescing = ServerQuiescingHelper(group: group)
    #endif
  }

  func run() async throws {
    #if canImport(Network)
      let parameters = NWParameters.tcp
      parameters.requiredLocalEndpoint = try address.asEndpoint()
      let options = NWProtocolWebSocket.Options()
      options.autoReplyPing = true
      options.setClientRequestHandler(.global()) { _, additionalHeaders in
        self.authorize(additionalHeaders)
      }
      parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)

      let promise = group.next().makePromise(of: Void.self)

      let _once = Mutex(false)
      @Sendable func once(_ execute: () -> Void) {
        let onceToken = _once.withLock {
          if $0 {
            return false
          } else {
            $0 = true
            return true
          }
        }
        guard onceToken else { return }
        execute()
      }

      let task = Task {
        try await Task.sleep(for: .seconds(5))
        try Task.checkCancellation()

        guard listener?.state != .ready else { return }
        listener?.cancel()
        once {
          promise.fail(NWError.posix(.ETIMEDOUT))
        }
      }

      listener = try NWListener(using: parameters)
      listener?.stateUpdateHandler = { [weak self] in
        guard let self else { return }
        switch $0 {
        case .setup:
          break
        case .ready:
          // Update local address if needed.
          if address.port == 0 {
            switch address {
            case .hostPort(let host, _):
              guard let port = listener?.port?.rawValue else { return }
              localAddress = .hostPort(host: host, port: .init(rawValue: port))
            case .unix:
              localAddress = address
            case .url:
              break
            }
          } else {
            localAddress = address
          }
          task.cancel()
          once {
            promise.succeed()
          }
        case .waiting:
          break
        case .failed(let error):
          listener?.cancel()
          listener = nil
          once {
            promise.fail(error)
          }
        case .cancelled:
          listener = nil
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
            self.$outboundStreams.withLock {
              $0[ObjectIdentifier(connection)] = connection
            }
            self.syncHistory()
          case .failed, .cancelled:
            self.$outboundStreams.withLock {
              _ = $0.removeValue(forKey: ObjectIdentifier(connection))
            }
          @unknown default:
            break
          }
        }
        connection.start(queue: .global())
      }
      listener?.start(queue: .global())
      try await promise.futureResult.get()
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

      localAddress = try channel.channel.localAddress?.asAddress()
      _ = Task {
        try await withThrowingDiscardingTaskGroup { g in
          try await channel.executeThenClose { inbound in
            for try await negotiationResult in inbound {
              g.addTask {
                let childChannel = try await negotiationResult.get()

                let key = ObjectIdentifier(childChannel.channel)
                let (stream, continuation) = AsyncStream.makeStream(of: ByteBuffer.self)
                self.$outboundStreams.withLock {
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

                self.$outboundStreams.withLock {
                  _ = $0.removeValue(forKey: key)
                }
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
    self.$outboundStreams.withLock { outboundStreams in
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
      self.closePromise.futureResult.cascade(to: promise)
      self.listener?.cancel()
    #else
      self.quiescing.initiateShutdown(promise: promise)
    #endif
    try await promise.futureResult.get()
  }

  func send(_ conn: Connection) async {
    self.$requestTaskMap.withLock {
      $0[conn.taskIdentifier] = conn
    }
    syncHistory()
  }

  private func syncHistory() {
    self.$requestTaskMap.withLock {
      guard !outboundStreams.isEmpty, !$0.isEmpty else {
        return
      }

      guard let data = try? coder.encode(Array($0.values)) else {
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
