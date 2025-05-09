//
// See LICENSE.txt for license information
//

import Anlzr
import Crypto
import HTTPTypes
import NEAddressProcessing
import NEVMESS
import NIOCore
import NIOHTTP1
import NIOWebSocket
import _NIOBase64
import _ResourceProcessing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

private final class NEVMESSWebSocketClientUpgrader<Output: Sendable>:
  NIOTypedHTTPClientProtocolUpgrader
{

  /// RFC 6455 specs this as the required entry in the Upgrade header.
  let supportedProtocol: String = "websocket"

  /// None of the websocket headers are actually defined as 'required'.
  let requiredUpgradeHeaders: [String] = []

  private let requestKey: String = randomRequestKey()
  private let maxFrameSize: Int = 1 << 14
  private let automaticErrorHandling: Bool = true
  private let contentSecurity: ContentSecurity
  private let userID: UUID
  private let commandCode: CommandCode
  private let destinationAddress: Address
  private let upgradePipeline: @Sendable (Channel, HTTPResponseHead) -> EventLoopFuture<Output>

  /// - Parameters:
  ///   - requestKey: sent to the server in the `Sec-WebSocket-Key` HTTP header. Default is random request key.
  ///   - maxFrameSize: largest incoming `WebSocketFrame` size in bytes. Default is 16,384 bytes.
  ///   - automaticErrorHandling: If true, adds `WebSocketProtocolErrorHandler` to the channel pipeline to catch and respond to WebSocket protocol errors. Default is true.
  ///   - upgradePipelineHandler: called once the upgrade was successful
  init(
    contentSecurity: ContentSecurity = .aes128Gcm,
    userID: UUID,
    commandCode: CommandCode = .tcp,
    destinationAddress: Address,
    upgradePipeline: @escaping @Sendable (Channel, HTTPResponseHead) -> EventLoopFuture<Output>
  ) {
    self.contentSecurity = contentSecurity
    self.userID = userID
    self.commandCode = commandCode
    self.destinationAddress = destinationAddress
    self.upgradePipeline = upgradePipeline
  }

  /// Generates a random WebSocket Request Key by generating 16 bytes randomly and encoding them as a base64 string as defined in RFC6455 https://tools.ietf.org/html/rfc6455#section-4.1
  /// - Parameter generator: the `RandomNumberGenerator` used as a the source of randomness
  /// - Returns: base64 encoded request key
  static func randomRequestKey<Generator>(
    using generator: inout Generator
  ) -> String where Generator: RandomNumberGenerator {
    var buffer = ByteBuffer()
    buffer.reserveCapacity(minimumWritableBytes: 16)
    /// we may want to use `randomBytes(count:)` once the proposal is accepted: https://forums.swift.org/t/pitch-requesting-larger-amounts-of-randomness-from-systemrandomnumbergenerator/27226
    buffer.writeMultipleIntegers(
      UInt64.random(in: UInt64.min...UInt64.max, using: &generator),
      UInt64.random(in: UInt64.min...UInt64.max, using: &generator)
    )
    return String(_base64Encoding: buffer.readableBytesView)
  }

  /// Generates a random WebSocket Request Key by generating 16 bytes randomly using the `SystemRandomNumberGenerator` and encoding them as a base64 string as defined in RFC6455 https://tools.ietf.org/html/rfc6455#section-4.1.
  /// - Returns: base64 encoded request key
  @inlinable
  static func randomRequestKey() -> String {
    var generator = SystemRandomNumberGenerator()
    return NEVMESSWebSocketClientUpgrader.randomRequestKey(using: &generator)
  }

  func addCustom(upgradeRequestHeaders: inout NIOHTTP1.HTTPHeaders) {
    upgradeRequestHeaders.add(name: "Sec-WebSocket-Key", value: requestKey)
    upgradeRequestHeaders.add(name: "Sec-WebSocket-Version", value: "13")
  }

  func shouldAllowUpgrade(upgradeResponse: NIOHTTP1.HTTPResponseHead) -> Bool {
    let acceptValueHeader = upgradeResponse.headers["Sec-WebSocket-Accept"]

    guard acceptValueHeader.count == 1 else {
      return false
    }

    let magicWebSocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    // Validate the response key in 'Sec-WebSocket-Accept'.
    var hasher = Insecure.SHA1()
    hasher.update(data: Array(requestKey.utf8))
    hasher.update(data: Array(magicWebSocketGUID.utf8))

    let expectedAcceptValue = String(_base64Encoding: Array(hasher.finalize()))

    return expectedAcceptValue == acceptValueHeader[0]
  }

  func upgrade(channel: any Channel, upgradeResponse: NIOHTTP1.HTTPResponseHead)
    -> NIOCore.EventLoopFuture<Output>
  {
    upgrade(channel: channel, response: upgradeResponse, upgrade: upgradePipeline)
  }

  private func upgrade(
    channel: any Channel, response: HTTPResponseHead,
    upgrade: @escaping @Sendable (Channel, HTTPResponseHead) -> EventLoopFuture<Output>
  )
    -> NIOCore.EventLoopFuture<Output>
  {
    channel.eventLoop.makeCompletedFuture {
      try channel.pipeline.syncOperations.addHandler(WebSocketFrameEncoder())
      try channel.pipeline.syncOperations.addHandler(
        ByteToMessageHandler(WebSocketFrameDecoder(maxFrameSize: maxFrameSize))
      )
      if automaticErrorHandling {
        try channel.pipeline.syncOperations.addHandler(WebSocketProtocolErrorHandler())
      }
      try channel.pipeline.syncOperations.addHandler(NEVMESSWebSocketFrameProducer())
      _ = try channel.pipeline.syncOperations.configureVMESSPipeline(
        contentSecurity: contentSecurity,
        user: userID,
        commandCode: commandCode,
        destinationAddress: destinationAddress
      ) {
        channel.eventLoop.makeSucceededVoidFuture()
      }
    }
    .flatMap {
      upgrade(channel, response)
    }
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Channel {

  func configureAsyncVMESSTunnelPipeline<Output>(
    contentSecurity: ContentSecurity,
    user: UUID,
    commandCode: CommandCode = .tcp,
    destinationAddress: Address,
    ws: AnyProxy.WebSocket,
    position: ChannelPipeline.Position = .last,
    upgrade: @escaping @Sendable (Channel, HTTPResponseHead) -> EventLoopFuture<Output>
  ) -> EventLoopFuture<EventLoopFuture<Output>> where Output: Sendable {
    if eventLoop.inEventLoop {
      return eventLoop.makeCompletedFuture {
        try self.pipeline.syncOperations.configureAsyncVMESSTunnelPipeline(
          contentSecurity: contentSecurity,
          user: user,
          commandCode: commandCode,
          destinationAddress: destinationAddress,
          ws: ws,
          upgrade: upgrade
        )
      }
    } else {
      return eventLoop.submit {
        try self.pipeline.syncOperations.configureAsyncVMESSTunnelPipeline(
          contentSecurity: contentSecurity,
          user: user,
          commandCode: commandCode,
          destinationAddress: destinationAddress,
          ws: ws,
          upgrade: upgrade
        )
      }
    }
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ChannelPipeline.SynchronousOperations {

  fileprivate func configureAsyncVMESSTunnelPipeline<Output>(
    contentSecurity: ContentSecurity,
    user: UUID,
    commandCode: CommandCode = .tcp,
    destinationAddress: Address,
    ws: AnyProxy.WebSocket,
    position: ChannelPipeline.Position = .last,
    upgrade: @escaping @Sendable (Channel, HTTPResponseHead) -> EventLoopFuture<Output>
  ) throws -> EventLoopFuture<Output> where Output: Sendable {
    self.eventLoop.assertInEventLoop()

    let requestEncoder = HTTPRequestEncoder(configuration: .init())
    let responseDecoder = ByteToMessageHandler(
      HTTPResponseDecoder(leftOverBytesStrategy: .dropBytes)
    )
    var httpHandlers = [RemovableChannelHandler]()
    httpHandlers.reserveCapacity(3)
    httpHandlers.append(requestEncoder)
    httpHandlers.append(responseDecoder)

    try self.addHandler(requestEncoder)
    try self.addHandler(responseDecoder)

    let headerValidationHandler = NIOHTTPRequestHeadersValidator()
    try self.addHandler(headerValidationHandler)
    httpHandlers.append(headerValidationHandler)

    var headers = HTTPHeaders()
    if let additionalHTTPFields = ws.additionalHTTPFields {
      for field in additionalHTTPFields {
        headers.replaceOrAdd(name: field.name.rawName, value: field.value)
      }
    }
    headers.add(name: "Host", value: "\(destinationAddress)")
    headers.add(name: "Content-Length", value: "0")

    let request = HTTPRequestHead(
      version: .http1_1,
      method: .GET,
      uri: ws.uri,
      headers: headers
    )

    let upgraders = [
      NEVMESSWebSocketClientUpgrader(
        contentSecurity: .aes128Gcm,
        userID: user,
        commandCode: .tcp,
        destinationAddress: destinationAddress,
        upgradePipeline: upgrade
      )
    ]

    let fallback: @Sendable (any Channel) -> EventLoopFuture<Output> = { channel in
      channel.close().flatMap {
        channel.eventLoop.makeFailedFuture(AnlzrError.connectionRefused)
      }
    }

    let upgrader = NIOTypedHTTPClientUpgradeHandler(
      httpHandlers: httpHandlers,
      upgradeConfiguration: .init(
        upgradeRequestHead: request,
        upgraders: upgraders,
        notUpgradingCompletionHandler: fallback
      )
    )
    try self.addHandler(upgrader)
    return upgrader.upgradeResultFuture
  }
}
