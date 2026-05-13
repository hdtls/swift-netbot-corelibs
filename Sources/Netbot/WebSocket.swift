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

import NIOCore
import NIOWebSocket

/// A handler that unmask inbound `WebSocketFrame` to `ByteBuffer`, it also mask all outbound
/// `ByteBuffer` to `WebSocketFrame` with `.binary` opcode.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
final class WebSocketFrameToByteBufferCodec: ChannelInboundHandler, ChannelOutboundHandler {

  typealias InboundIn = WebSocketFrame
  typealias InboundOut = ByteBuffer
  typealias OutboundIn = ByteBuffer
  typealias OutboundOut = WebSocketFrame

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let frame = unwrapInboundIn(data)
    switch frame.opcode {
    case .text, .binary:
      context.fireChannelRead(wrapInboundOut(frame.unmaskedData))
    default:
      break
    }
  }

  func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
    let buffer = unwrapOutboundIn(data)
    context.write(
      wrapOutboundOut(
        WebSocketFrame(fin: true, opcode: .binary, maskKey: .random(), data: buffer)
      ),
      promise: promise
    )
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension WebSocketFrameToByteBufferCodec: Sendable {}

/// A handler that response to control codes.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
final class WebSocketAutoReply: ChannelInboundHandler {

  typealias InboundIn = WebSocketFrame
  typealias OutboundOut = WebSocketFrame
  private var waitingForClose = false

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let frame = unwrapInboundIn(data)

    switch frame.opcode {
    case .connectionClose:
      guard !waitingForClose else {
        context.close(promise: nil)
        return
      }
      let promise = context.eventLoop.makePromise(of: Void.self)
      var unmaskedData = frame.unmaskedData
      let error = unmaskedData.readWebSocketErrorCode() ?? .unknown(1005)
      fail(error: error, context: context)
      promise.futureResult.assumeIsolatedUnsafeUnchecked().whenComplete { _ in
        context.close(promise: nil)
      }
    case .ping:
      guard frame.fin else {
        fail(error: .protocolError, context: context)
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
      guard !frame.fin else {
        return
      }
      fail(error: .protocolError, context: context)
    default:
      context.fireChannelRead(data)
    }
  }

  private func fail(
    error: WebSocketErrorCode,
    context: ChannelHandlerContext,
    promise: EventLoopPromise<Void>? = nil
  ) {
    context.eventLoop.assertInEventLoop()

    guard context.channel.isActive else {
      promise?.succeed(())
      return
    }
    guard !waitingForClose else {
      promise?.succeed(())
      return
    }
    waitingForClose = true

    let codeAsInt = UInt16(webSocketErrorCode: .protocolError)

    /// Code 1005 and 1006 are used to report errors to the application, but must never be sent over
    /// the wire (per https://tools.ietf.org/html/rfc6455#section-7.4)
    let errorCode: WebSocketErrorCode =
      codeAsInt == 1005 || codeAsInt == 1006 ? .normalClosure : .protocolError

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
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension WebSocketAutoReply: @unchecked Sendable {}
