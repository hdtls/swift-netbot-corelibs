//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if DEBUG
  import Logging
  import NIOCore

  @available(SwiftStdlib 5.3, *)
  final class EventLogHandler: Sendable {

    private let logger: Logger
    private let metadata: Logger.Metadata

    init(logger: Logger, metadata: Logger.Metadata) {
      self.logger = logger
      self.metadata = metadata
    }

    private func trace(_ message: String, _ context: ChannelHandlerContext) {
      logger.trace("\(context.name) \(message)", metadata: metadata)
    }
  }

  @available(SwiftStdlib 5.3, *)
  extension EventLogHandler: ChannelInboundHandler {

    typealias InboundIn = NIOAny

    func channelRegistered(context: ChannelHandlerContext) {
      trace("channelRegistered", context)
      context.fireChannelRegistered()
    }

    func channelUnregistered(context: ChannelHandlerContext) {
      trace("channelUnregistered", context)
      context.fireChannelUnregistered()
    }

    func channelActive(context: ChannelHandlerContext) {
      trace("channelActive", context)
      context.fireChannelActive()
    }

    func channelInactive(context: ChannelHandlerContext) {
      trace("channelInactive", context)
      context.fireChannelInactive()
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
      trace("channelRead \(data)", context)
      context.fireChannelRead(data)
    }

    func channelReadComplete(context: ChannelHandlerContext) {
      trace("channelReadComplete", context)
      context.fireChannelReadComplete()
    }

    func channelWritabilityChanged(context: ChannelHandlerContext) {
      trace("channelWritabilityChanged \(context.channel.isWritable)", context)
      context.fireChannelWritabilityChanged()
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
      trace("userInboundEventTriggered \(event)", context)
      context.fireUserInboundEventTriggered(event)
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
      trace("errorCaught \(error)", context)
      context.fireErrorCaught(error)
    }
  }

  @available(SwiftStdlib 5.3, *)
  extension EventLogHandler: ChannelOutboundHandler {

    typealias OutboundIn = NIOAny

    func register(context: ChannelHandlerContext, promise: EventLoopPromise<Void>?) {
      trace("register", context)
      context.register(promise: promise)
    }

    func bind(
      context: ChannelHandlerContext, to address: SocketAddress, promise: EventLoopPromise<Void>?
    ) {
      trace("bind \(address)", context)
      context.bind(to: address, promise: promise)
    }

    func connect(
      context: ChannelHandlerContext, to address: SocketAddress, promise: EventLoopPromise<Void>?
    ) {
      trace("connect \(address)", context)
      context.connect(to: address, promise: promise)
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
      trace("write \(data)", context)
      context.write(data, promise: promise)
    }

    func flush(context: ChannelHandlerContext) {
      trace("flush", context)
      context.flush()
    }

    func read(context: ChannelHandlerContext) {
      trace("read", context)
      context.read()
    }

    func close(context: ChannelHandlerContext, mode: CloseMode, promise: EventLoopPromise<Void>?) {
      trace("close \(mode)", context)
      context.close(mode: mode, promise: promise)
    }

    func triggerUserOutboundEvent(
      context: ChannelHandlerContext, event: Any, promise: EventLoopPromise<Void>?
    ) {
      trace("triggerUserOutboundEvent \(event)", context)
      context.triggerUserOutboundEvent(event, promise: promise)
    }
  }
#endif
