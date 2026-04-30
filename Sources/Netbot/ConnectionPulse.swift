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

import NEAddressProcessing
import NIOCore
import NetbotLite
import NetbotLiteData

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

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  import NIOConcurrencyHelpers
#else
  import Synchronization
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
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

  private func run0() async throws {
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
              channel.pipeline.addHandler(WebSocketAutomator())
                .flatMapThrowing {
                  try NIOAsyncChannel<ByteBuffer, ByteBuffer>(
                    wrappingChannelSynchronously: channel)
                }
            })
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

  func run() async throws {
    Task(priority: .high) {
      try await run0()
    }
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

#if !canImport(Network)
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  final class WebSocketAutomator: ChannelInboundHandler, ChannelOutboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = WebSocketFrame

    private var waitingForClose = false

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
      let frame = unwrapInboundIn(data)
      switch frame.opcode {
      case .continuation:
        break
      case .text, .binary:
        context.fireChannelRead(wrapInboundOut(frame.unmaskedData))
      case .connectionClose:
        guard !waitingForClose else {
          context.close(promise: nil)
          return
        }
        let promise = context.eventLoop.makePromise(of: Void.self)
        var unmaskedData = frame.unmaskedData
        let code = unmaskedData.readWebSocketErrorCode() ?? .unknown(1005)
        close(context: context, code: code, promise: promise)
        promise.futureResult.assumeIsolated().whenComplete { _ in
          context.close(promise: nil)
        }
      case .ping:
        guard frame.fin else {
          close(context: context, code: .protocolError, promise: nil)
          return
        }
        let response = WebSocketFrame(
          fin: true,
          opcode: .pong,
          maskKey: .random(),
          data: frame.unmaskedData
        )
        context.writeAndFlush(wrapOutboundOut(response), promise: nil)
      case .pong:
        guard frame.fin else {
          close(context: context, code: .protocolError, promise: nil)
          return
        }
      default:
        break
      }
    }

    private func close(
      context: ChannelHandlerContext,
      code: WebSocketErrorCode = .goingAway,
      promise: EventLoopPromise<Void>?
    ) {
      guard context.channel.isActive else {
        promise?.succeed(())
        return
      }
      guard !waitingForClose else {
        promise?.succeed(())
        return
      }
      waitingForClose = true

      let codeAsInt = UInt16(webSocketErrorCode: code)

      /// Code 1005 and 1006 are used to report errors to the application, but must never be sent over
      /// the wire (per https://tools.ietf.org/html/rfc6455#section-7.4)
      let errorCode: WebSocketErrorCode =
        codeAsInt == 1005 || codeAsInt == 1006 ? .normalClosure : code

      var buffer = context.channel.allocator.buffer(capacity: MemoryLayout<UInt16>.size)
      buffer.write(webSocketErrorCode: errorCode)
      let frame = WebSocketFrame(
        fin: true,
        opcode: .connectionClose,
        maskKey: .random(),
        data: buffer
      )
      context.writeAndFlush(wrapOutboundOut(frame), promise: promise)
    }

    func write(
      context: ChannelHandlerContext,
      data: NIOAny,
      promise: EventLoopPromise<Void>?
    ) {
      let buffer = unwrapOutboundIn(data)
      //    let frame = WebSocketFrame(fin: true, opcode: .binary, maskKey: .random(), data: buffer)
      let frame = WebSocketFrame(fin: true, opcode: .binary, data: buffer)
      context.write(wrapOutboundOut(frame), promise: promise)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension WebSocketAutomator: @unchecked Sendable {}
#endif
