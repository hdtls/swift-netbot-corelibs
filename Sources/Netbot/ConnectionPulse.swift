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
  import ServiceLifecycle
#endif

@available(SwiftStdlib 6.0, *)
@Lockable final class ConnectionPulse: ConnectionPublisher, Sendable {

  private let group: any EventLoopGroup
  private let address: Address
  var localAddress: Address? = nil

  #if canImport(Network)
    private var outboundStreams: [ObjectIdentifier: NWConnection] = [:]
  #else
    private var outboundStreams: [ObjectIdentifier: AsyncStream<ByteBuffer>.Continuation] = [:]
  #endif
  private let coder = JSONEncoder()

  private var requestTaskMap: [UInt64: Connection] = [:]

  init(group: any EventLoopGroup, address: Address) {
    self.group = group
    self.address = address
  }

  #if canImport(Network)
    func run() async throws {
      let parameters = NWParameters.tcp
      parameters.requiredLocalEndpoint = try address.asEndpoint()
      let options = NWProtocolWebSocket.Options()
      options.autoReplyPing = true
      options.setClientRequestHandler(.global()) { _, additionalHeaders in
        self.authorize(additionalHeaders)
      }
      parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)

      let promise = group.next().makePromise(of: Void.self)
      let closePromise = group.next().makePromise(of: Void.self)
      promise.futureResult.cascade(to: closePromise)

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

      let listener = try NWListener(using: parameters)

      let task = Task {
        try await Task.sleep(for: .seconds(5))
        try Task.checkCancellation()

        guard listener.state != .ready else { return }
        listener.cancel()
        once {
          promise.fail(NWError.posix(.ETIMEDOUT))
        }
      }

      listener.stateUpdateHandler = { [weak self] in
        guard let self else { return }
        switch $0 {
        case .setup:
          break
        case .ready:
          // Update local address if needed.
          if address.port == 0 {
            switch address {
            case .hostPort(let host, _):
              guard let port = listener.port?.rawValue else { return }
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
        case .waiting:
          break
        case .failed(let error):
          once {
            promise.fail(error)
          }
        case .cancelled:
          closePromise.succeed()
        @unknown default:
          break
        }
      }
      listener.newConnectionHandler = { connection in
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

      try await withTaskCancellationHandler {
        if Task.isCancelled {
          // The cancellation/shutdown handler will have closed the socket. Just await the closeFuture here.
          try? await closePromise.futureResult.get()
          return
        }

        listener.start(queue: .global())
        try await closePromise.futureResult.get()
      } onCancel: {
        self.$outboundStreams.withLock { outboundStreams in
          for outboundStream in outboundStreams {
            outboundStream.value.cancel()
          }
          outboundStreams.removeAll()
        }
        listener.cancel()
      }
    }
  #else
    func run() async throws {
      let serverQuiescingHelper = ServerQuiescingHelper(group: group)

      let serverChannel = try await ServerBootstrap(group: group)
        .serverChannelInitializer { channel in
          channel.eventLoop.makeCompletedFuture {
            try channel.pipeline.syncOperations.addHandler(
              serverQuiescingHelper.makeServerChannelHandler(channel: channel)
            )
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

      try await withTaskCancellationHandler {
        try await withGracefulShutdownHandler {
          if Task.isCancelled || Task.isShuttingDownGracefully {
            // The cancellation/shutdown handler will have closed the socket. Just await the closeFuture here.
            try? await serverChannel.channel.closeFuture.get()
            return
          }

          guard (try? serverChannel.channel.localAddress?.asAddress()) != nil else {
            fatalError(
              "Address was unable to bind. Please check that the socket was not closed or that the address family was understood."
            )
          }

          try await serverChannel.executeThenClose { inbound in
            try await withThrowingDiscardingTaskGroup { g in
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
        } onGracefulShutdown: {
          serverQuiescingHelper.initiateShutdown(promise: nil)
        }
      } onCancel: {
        self.$outboundStreams.withLock { outboundStreams in
          for outboundStream in outboundStreams {
            outboundStream.value.finish()
          }
          outboundStreams.removeAll()
        }
        serverChannel.channel.close(promise: nil)
      }
    }
  #endif

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
