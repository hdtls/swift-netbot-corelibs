//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore

#if canImport(Network)
  import Network
#else
  import NIOExtras
  import NIOHTTP1
  import NIOPosix
  import NIOWebSocket
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
@Lockable final class ConnectionPulse: ConnectionTransmissionService, Sendable {

  private let group: any EventLoopGroup
  private let address: Address
  #if canImport(Network)
    private var outboundStreams: [ObjectIdentifier: NWConnection]
    private var closeFuture: EventLoopFuture<Void> {
      promise.futureResult
    }
    private let promise: EventLoopPromise<Void>
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
      self.promise = group.any().makePromise()
    #else
      self.quiescing = ServerQuiescingHelper(group: group)
    #endif
    self._connections = .init([:])
  }

  func run() async throws {
    #if canImport(Network)
      let parameters = NWParameters.tcp
      parameters.requiredLocalEndpoint = try address.asEndpoint()
      let options = NWProtocolWebSocket.Options()
      options.autoReplyPing = true
      options.setClientRequestHandler(.global()) { subprotocols, additionalHeaders in
        self.authorize(additionalHeaders)
      }
      parameters.defaultProtocolStack.applicationProtocols.insert(options, at: 0)

      let listener = try NWListener(using: parameters)
      listener.stateUpdateHandler = { [self] in
        switch $0 {
        case .setup, .ready:
          break
        case .waiting(let error):
          promise.fail(error)
        case .failed(let error):
          promise.fail(error)
        case .cancelled:
          promise.succeed()
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
      listener.start(queue: .global())
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
            upgradePipelineHandler: { channel, head in
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
                  channel.eventLoop.makeFailedFuture(AnlzrError.connectionRefused)
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

  func run0() async throws {
    Task(priority: .high) {
      try await run()
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

  func shutdownGracyfully() async throws {
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

    let promise = group.any().makePromise(of: Void.self)
    #if canImport(Network)
      self.promise.futureResult.cascade(to: promise)
    #else
      quiescing.initiateShutdown(promise: promise)
    #endif
    try await promise.futureResult.get()
  }

  func shutdownGracyFully0() async {
    try? await shutdownGracyfully()
  }

  func push(_ conn: Connection) async {
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
  @available(SwiftStdlib 5.3, *)
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

  @available(SwiftStdlib 5.3, *)
  extension WebSocketAutomator: @unchecked Sendable {}
#endif
