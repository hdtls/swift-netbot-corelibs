// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2021 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NIOCore

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
final class GlueHandler: ChannelHandler, @unchecked Sendable {

  private weak var partner: GlueHandler?

  private var context: ChannelHandlerContext?

  private var pendingRead: Bool = false

  private init() {}

  public static func matchedPair() -> (GlueHandler, GlueHandler) {
    let first = GlueHandler()
    let second = GlueHandler()

    first.partner = second
    second.partner = first

    return (first, second)
  }

  func handlerAdded(context: ChannelHandlerContext) {
    partner?.context?.eventLoop.assertInEventLoop()
    self.context = context
  }

  func handlerRemoved(context: ChannelHandlerContext) {
    self.context = nil
    self.partner = nil
  }

  private func close(mode: CloseMode = .all, promise: EventLoopPromise<Void>?) {
    context?.close(mode: mode, promise: promise)
  }

  private func write(_ data: NIOAny, promise: EventLoopPromise<Void>?) {
    context?.write(data, promise: promise)
  }

  private func flush() {
    context?.flush()
  }

  private func becameWritable() {
    if pendingRead {
      pendingRead = false
      context?.read()
    }
  }

  private var isWritable: Bool {
    return context?.channel.isWritable ?? false
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension GlueHandler: ChannelInboundHandler {

  typealias InboundIn = NIOAny

  func channelInactive(context: ChannelHandlerContext) {
    context.fireChannelInactive()
    partner?.context?.eventLoop.assertInEventLoop()
    partner?.close(promise: nil)
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    context.fireChannelRead(data)
    partner?.context?.eventLoop.assertInEventLoop()
    partner?.write(data, promise: nil)
  }

  func channelReadComplete(context: ChannelHandlerContext) {
    context.fireChannelReadComplete()
    partner?.context?.eventLoop.assertInEventLoop()
    partner?.flush()
  }

  func channelWritabilityChanged(context: ChannelHandlerContext) {
    context.fireChannelWritabilityChanged()
    if context.channel.isWritable {
      partner?.context?.eventLoop.assertInEventLoop()
      partner?.becameWritable()
    }
  }

  func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
    context.fireUserInboundEventTriggered(event)

    if let event = event as? ChannelEvent, case .inputClosed = event {
      partner?.context?.eventLoop.assertInEventLoop()
      // We have read EOF.
      partner?.close(mode: .output, promise: nil)
    }

    if event is ChannelShouldQuiesceEvent {
      context.close(promise: nil)
    }
  }

  func errorCaught(context: ChannelHandlerContext, error: any Error) {
    context.fireErrorCaught(error)
    partner?.context?.eventLoop.assertInEventLoop()
    partner?.close(promise: nil)
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension GlueHandler: ChannelOutboundHandler {

  typealias OutboundIn = NIOAny

  func read(context: ChannelHandlerContext) {
    partner?.context?.eventLoop.assertInEventLoop()
    if let partner, partner.isWritable {
      context.read()
    } else {
      pendingRead = true
    }
  }
}
