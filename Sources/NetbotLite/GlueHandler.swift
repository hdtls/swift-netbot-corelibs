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

import NIOCore

@available(SwiftStdlib 6.0, *)
final class GlueHandler: ChannelHandler, @unchecked Sendable {

  private weak var partner: GlueHandler?

  private var eventLoop: (any EventLoop)?
  private var context: NIOLoopBound<ChannelHandlerContext>?

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
    self.context = context.loopBound
    self.eventLoop = context.eventLoop
  }

  func handlerRemoved(context: ChannelHandlerContext) {
    self.context = nil
    self.partner = nil
  }

  private func close(mode: CloseMode = .all, promise: EventLoopPromise<Void>?) {
    eventLoop?.execute {
      self.context?.value.close(mode: mode, promise: promise)
    }
  }

  private func write(_ data: NIOAny, promise: EventLoopPromise<Void>?) {
    let data = NIOLoopBound(data, eventLoop: eventLoop!)
    eventLoop?.execute {
      self.context?.value.write(data.value, promise: promise)
    }
  }

  private func flush() {
    eventLoop?.execute {
      self.context?.value.flush()
    }
  }

  private func becameWritable() {
    if pendingRead {
      pendingRead = false
      eventLoop?.execute {
        self.context?.value.read()
      }
    }
  }

  private var isWritable: Bool {
    return context?.value.channel.isWritable ?? false
  }
}

@available(SwiftStdlib 6.0, *)
extension GlueHandler: ChannelInboundHandler {

  typealias InboundIn = NIOAny

  func channelInactive(context: ChannelHandlerContext) {
    context.fireChannelInactive()
    partner?.close(promise: nil)
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    context.fireChannelRead(data)
    partner?.write(data, promise: nil)
  }

  func channelReadComplete(context: ChannelHandlerContext) {
    context.fireChannelReadComplete()
    partner?.flush()
  }

  func channelWritabilityChanged(context: ChannelHandlerContext) {
    context.fireChannelWritabilityChanged()
    if context.channel.isWritable {
      partner?.becameWritable()
    }
  }

  func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
    context.fireUserInboundEventTriggered(event)

    if let event = event as? ChannelEvent, case .inputClosed = event {
      // We have read EOF.
      partner?.close(mode: .output, promise: nil)
    }

    if event is ChannelShouldQuiesceEvent {
      context.close(promise: nil)
    }
  }

  func errorCaught(context: ChannelHandlerContext, error: any Error) {
    context.fireErrorCaught(error)
    partner?.close(promise: nil)
  }
}

@available(SwiftStdlib 6.0, *)
extension GlueHandler: ChannelOutboundHandler {

  typealias OutboundIn = NIOAny

  func read(context: ChannelHandlerContext) {
    guard let partner else {
      pendingRead = true
      return
    }

    let context = context.loopBound

    partner.eventLoop?.execute {
      if partner.isWritable {
        self.eventLoop?.execute {
          context.value.read()
        }
      } else {
        self.eventLoop?.execute {
          self.pendingRead = true
        }
      }
    }
  }
}
