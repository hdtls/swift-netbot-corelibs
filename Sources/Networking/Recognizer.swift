//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2022 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
enum CharacteristicIdentificationResult: Equatable, Sendable {

  case identified(String)

  case fallback
}

@available(SwiftStdlib 5.3, *)
protocol Recognizer {

  func recognize(_ data: ByteBuffer) -> CharacteristicIdentificationResult
}

@available(SwiftStdlib 5.3, *)
class CharacteristicIdentificationHandler<Output>: ChannelInboundHandler, RemovableChannelHandler
where Output: Sendable {

  typealias InboundIn = ByteBuffer

  private enum EventBuffer {
    case channelRead(NIOAny)
    case channelReadComplete
  }

  private enum RecognizeState {
    case waitingForData
    case waitingForComplete
    case completed
  }

  private var eventBuffer: CircularBuffer<EventBuffer>

  private var state: RecognizeState

  private let recognizer: any Recognizer

  private let completion: (CharacteristicIdentificationResult) -> EventLoopFuture<Output>

  public var characteristicIdentificationResultFuture: EventLoopFuture<Output> {
    precondition(
      self.characteristicIdentificationResultPromise != nil,
      "Tried to access the negotiation result before the handler was added to a pipeline"
    )
    return self.characteristicIdentificationResultPromise.futureResult
  }

  private var characteristicIdentificationResultPromise: EventLoopPromise<Output>!

  init(
    recognizer: any Recognizer,
    completion: @escaping @Sendable (CharacteristicIdentificationResult) -> EventLoopFuture<Output>
  ) {
    self.eventBuffer = .init()
    self.state = .waitingForData
    self.completion = completion
    self.recognizer = recognizer
  }

  func handlerAdded(context: ChannelHandlerContext) {
    characteristicIdentificationResultPromise = context.eventLoop.makePromise(of: Output.self)
  }

  func handlerRemoved(context: ChannelHandlerContext) {
    guard case .completed = state else {
      characteristicIdentificationResultPromise.fail(ChannelError.inappropriateOperationForState)
      return
    }
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    switch state {
    case .waitingForData:
      eventBuffer.append(.channelRead(data))
      state = .waitingForComplete

      completion(recognizer.recognize(unwrapInboundIn(data)))
        .hop(to: context.eventLoop)
        .assumeIsolatedUnsafeUnchecked()
        .whenComplete {
          switch $0 {
          case .success(let value):
            self.characteristicIdentificationResultPromise.succeed(value)
            self.state = .completed
            context.pipeline.syncOperations.removeHandler(context: context, promise: nil)
          case .failure(let error):
            self.characteristicIdentificationResultPromise.fail(error)
            context.fireErrorCaught(error)
            context.close(promise: nil)
          }
        }
    case .waitingForComplete:
      eventBuffer.append(.channelRead(data))

    case .completed:
      context.fireChannelRead(data)
    }
  }

  func channelReadComplete(context: ChannelHandlerContext) {
    eventBuffer.append(.channelReadComplete)
  }

  func removeHandler(
    context: ChannelHandlerContext, removalToken: ChannelHandlerContext.RemovalToken
  ) {
    while !eventBuffer.isEmpty {
      switch eventBuffer.removeFirst() {
      case .channelRead(let data):
        context.fireChannelRead(data)
      case .channelReadComplete:
        context.fireChannelReadComplete()
      }
    }
    context.leavePipeline(removalToken: removalToken)
  }
}

@available(*, unavailable)
extension CharacteristicIdentificationHandler: Sendable {}

/// This handler can be used in channels that are acting as the server to recognize whether channel is communicating with SSL/TLS protocol.
@available(SwiftStdlib 5.3, *)
struct NIOTLSRecognizer: Recognizer {

  func recognize(_ data: ByteBuffer) -> CharacteristicIdentificationResult {
    guard data.readableBytes >= 6 else {
      return .fallback
    }

    var byteBuffer = data

    // Byte   0  = SSL record type = 22 (SSL3_RT_HANDSHAKE)
    // Bytes 1-2 = SSL version (major/minor)
    // Bytes 3-4 = Length of data in the record (excluding the header itself).
    // Byte   5  = Handshake type
    // Bytes 6-8 = Length of data to follow in this record
    // Bytes 9-n = Command-specific data

    let contentType = byteBuffer.readInteger(as: UInt8.self)

    // SSL3_RT_HANDSHAKE 22(x'16')
    guard contentType == 0x16 else {
      return .fallback
    }

    // Skip bytes that represent as version and record data length.
    byteBuffer.moveReaderIndex(forwardBy: 4)

    let handshakeType = byteBuffer.readInteger(as: UInt8.self) ?? 0

    // SSL3_MT_HELLO_REQUEST (x'00')
    // SSL3_MT_CLIENT_HELLO (x'01')
    // SSL3_MT_SERVER_HELLO (x'02')
    // SSL3_MT_NEWSESSION_TICKET (x'04')
    // SSL3_MT_CERTIFICATE (x'0B')
    // SSL3_MT_SERVER_KEY_EXCHANGE (x'0C')
    // SSL3_MT_CERTIFICATE_REQUEST (x'0D')
    // SSL3_MT_SERVER_DONE (x'0E')
    // SSL3_MT_CERTIFICATE_VERIFY (x'0F')
    // SSL3_MT_CLIENT_KEY_EXCHANGE (x'10')
    // SSL3_MT_FINISHED (x'14')
    let handshakeTypes: [UInt8] = [
      0x00, 0x01, 0x02, 0x04, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x14,
    ]

    return handshakeTypes.contains(handshakeType) ? .identified("TLS") : .fallback
  }
}

@available(SwiftStdlib 5.3, *)
extension Recognizer where Self == NIOTLSRecognizer {

  static var tls: NIOTLSRecognizer {
    NIOTLSRecognizer()
  }
}

/// This handler can be used in channels that are acting as the server to recognize whether channel is communicating with HTTP protocol.
@available(SwiftStdlib 5.3, *)
struct PlainHTTPRecognizer: Recognizer {

  func recognize(_ data: ByteBuffer) -> CharacteristicIdentificationResult {
    // GET /uri HTTP/1.1\r\n
    let crlf = "\r\n"
    let contents = String(buffer: data)
    guard contents.contains(crlf), let firstLine = contents.components(separatedBy: crlf).first
    else {
      return .fallback
    }

    let components = firstLine.components(separatedBy: " ")
    guard components.count == 3, components[2].hasPrefix("HTTP") else {
      return .fallback
    }
    return .identified("HTTP")
  }
}

@available(SwiftStdlib 5.3, *)
extension Recognizer where Self == PlainHTTPRecognizer {

  static var http: PlainHTTPRecognizer {
    PlainHTTPRecognizer()
  }
}
