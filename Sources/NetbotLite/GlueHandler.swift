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

  private var eventLoop: (any EventLoop)? {
    context?.eventLoop
  }
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
    self.context = context
  }

  func handlerRemoved(context: ChannelHandlerContext) {
    self.context = nil
    self.partner = nil
  }
}

@available(SwiftStdlib 6.0, *)
extension GlueHandler: ChannelInboundHandler {

  typealias InboundIn = NIOAny

  func channelInactive(context: ChannelHandlerContext) {
    context.fireChannelInactive()

    guard let partner else { return }
    partner.eventLoop?.execute {
      partner.context?.close(promise: nil)
    }
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    context.fireChannelRead(data)

    guard let partner, let eventLoop = partner.eventLoop else { return }
    let data = NIOLoopBound(data, eventLoop: eventLoop)
    partner.eventLoop?.execute {
      partner.context?.write(data.value, promise: nil)
    }
  }

  func channelReadComplete(context: ChannelHandlerContext) {
    context.fireChannelReadComplete()

    guard let partner else { return }
    partner.eventLoop?.execute {
      partner.context?.flush()
    }
  }

  func channelWritabilityChanged(context: ChannelHandlerContext) {
    context.fireChannelWritabilityChanged()
    if context.channel.isWritable, let partner {
      partner.eventLoop?.execute {
        if partner.pendingRead {
          partner.pendingRead = false
          partner.context?.read()
        }
      }
    }
  }

  func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
    context.fireUserInboundEventTriggered(event)

    if let event = event as? ChannelEvent, case .inputClosed = event, let partner {
      // We have read EOF.
      partner.eventLoop?.execute {
        partner.context?.close(mode: .output, promise: nil)
      }
    }

    if event is ChannelShouldQuiesceEvent {
      context.close(promise: nil)
    }
  }

  func errorCaught(context: ChannelHandlerContext, error: any Error) {
    context.fireErrorCaught(error)

    guard let partner else { return }
    partner.eventLoop?.execute {
      partner.context?.fireErrorCaught(error)
    }
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
      if partner.context?.channel.isWritable ?? false {
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
