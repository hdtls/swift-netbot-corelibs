//
// See LICENSE.txt for license information
//

import CNELwIP
import NEAddressProcessing
import NIOCore

/// The type of all `channelInitializer` callbacks.
internal typealias ChannelInitializerCallback = @Sendable (any Channel) -> EventLoopFuture<Void>

final class ServerBootstrap {

  private let group: any EventLoop
  private var serverChannelInit: Optional<ChannelInitializerCallback>
  private var childChannelInit: Optional<ChannelInitializerCallback>

  public init(group: any EventLoop) {
    self.group = group
    self.serverChannelInit = .none
    self.childChannelInit = .none
  }

  @preconcurrency
  public func serverChannelInitializer(
    _ initializer: @escaping @Sendable (any Channel) -> EventLoopFuture<Void>
  ) -> Self {
    self.serverChannelInit = initializer
    return self
  }

  @preconcurrency
  public func childChannelInitializer(
    _ initializer: @escaping @Sendable (any Channel) -> EventLoopFuture<Void>
  ) -> Self {
    self.childChannelInit = initializer
    return self
  }

  public func bind(to address: SocketAddress) -> EventLoopFuture<any Channel> {
    bind0 { address }
  }

  public func bind(to address: Address) -> EventLoopFuture<any Channel> {
    bind0 { try address.address }
  }

  private func bind0(_ makeSocketAddress: () throws -> SocketAddress) -> EventLoopFuture<Channel> {
    let eventLoop = self.group
    let address: SocketAddress
    do {
      address = try makeSocketAddress()
    } catch {
      return eventLoop.makeFailedFuture(error)
    }

    let serverChannelInit = self.serverChannelInit ?? { _ in eventLoop.makeSucceededFuture(()) }
    let childChannelInit = self.childChannelInit

    return eventLoop.submit {
      let serverChannel = try ServerLwIPPCBChannel(
        protocolFamily: address.protocol,
        eventLoop: eventLoop
      )
      return serverChannelInit(serverChannel)
        .flatMap {
          do {
            try serverChannel.pipeline.syncOperations.addHandler(
              AcceptHandler(childChannelInitializer: childChannelInit),
              name: "AcceptHandler"
            )
            return serverChannel.registerAndDoSynchronously { serverChannel in
              serverChannel.bind(to: address)
            }
          } catch {
            return eventLoop.makeFailedFuture(error)
          }
        }.map {
          serverChannel as Channel
        }.flatMapError { error in
          serverChannel.close0(error: error, mode: .all, promise: nil)
          return eventLoop.makeFailedFuture(error)
        }
    }.flatMap {
      $0
    }
  }

  public func bind<Output: Sendable>(
    to address: SocketAddress,
    serverBackPressureStrategy: NIOAsyncSequenceProducerBackPressureStrategies.HighLowWatermark? =
      nil,
    childChannelInitializer: @escaping @Sendable (Channel) -> EventLoopFuture<Output>
  ) async throws -> NIOAsyncChannel<Output, Never> {
    try await bind0(
      { address },
      serverBackPressureStrategy: serverBackPressureStrategy,
      childChannelInitializer: childChannelInitializer
    )
    .get()
  }

  public func bind<Output: Sendable>(
    to address: Address,
    serverBackPressureStrategy: NIOAsyncSequenceProducerBackPressureStrategies.HighLowWatermark? =
      nil,
    childChannelInitializer: @escaping @Sendable (Channel) -> EventLoopFuture<Output>
  ) async throws -> NIOAsyncChannel<Output, Never> {
    try await bind0(
      { try address.address },
      serverBackPressureStrategy: serverBackPressureStrategy,
      childChannelInitializer: childChannelInitializer
    )
    .get()
  }

  private func bind0<Output>(
    _ makeSocketAddress: @escaping () throws -> SocketAddress,
    serverBackPressureStrategy: NIOAsyncSequenceProducerBackPressureStrategies.HighLowWatermark?,
    childChannelInitializer: @escaping @Sendable (Channel) -> EventLoopFuture<Output>,
  ) -> EventLoopFuture<NIOAsyncChannel<Output, Never>> {
    let eventLoop = self.group
    let address: SocketAddress
    do {
      address = try makeSocketAddress()
    } catch {
      return eventLoop.makeFailedFuture(error)
    }

    let serverChannelInit = self.serverChannelInit ?? { _ in eventLoop.makeSucceededFuture(()) }
    let childChannelInit = self.childChannelInit

    return eventLoop.submit {
      let serverChannel = try ServerLwIPPCBChannel(
        protocolFamily: address.protocol,
        eventLoop: eventLoop
      )
      return serverChannelInit(serverChannel)
        .flatMap { (_) -> EventLoopFuture<NIOAsyncChannel<Output, Never>> in
          do {
            try serverChannel.pipeline.syncOperations.addHandler(
              AcceptBackoffHandler(shouldForwardIOErrorCaught: false),
              name: "AcceptBackOffHandler"
            )
            try serverChannel.pipeline.syncOperations.addHandler(
              AcceptHandler(childChannelInitializer: childChannelInit),
              name: "AcceptHandler"
            )
            return serverChannel.registerAndDoSynchronously {
              $0.bind(to: address)
            }
            .flatMapThrowing {
              try NIOAsyncChannel<Output, Never>
                ._wrapAsyncChannelWithTransformations(
                  wrappingChannelSynchronously: serverChannel,
                  backPressureStrategy: serverBackPressureStrategy,
                  channelReadTransformation: { channel -> EventLoopFuture<Output> in
                    // The channelReadTransformation is run on the EL of the server channel
                    // We have to make sure that we execute child channel initializer on the
                    // EL of the child channel.
                    channel.eventLoop.flatSubmit {
                      childChannelInitializer(channel)
                    }
                  }
                )
            }
          } catch {
            return eventLoop.makeFailedFuture(error)
          }
        }.flatMapError {
          error -> EventLoopFuture<NIOAsyncChannel<Output, Never>> in
          serverChannel.close0(error: error, mode: .all, promise: nil)
          return eventLoop.makeFailedFuture(error)
        }
    }.flatMap {
      $0
    }
  }
}

extension ServerBootstrap {

  final class AcceptHandler: ChannelInboundHandler {
    typealias InboundIn = LwIPPCBChannel
    typealias InboundOut = LwIPPCBChannel

    private let childChannelInit: (@Sendable (Channel) -> EventLoopFuture<Void>)?

    init(childChannelInitializer: (@Sendable (Channel) -> EventLoopFuture<Void>)?) {
      self.childChannelInit = childChannelInitializer
    }

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
      if event is ChannelShouldQuiesceEvent {
        let loopBoundContext = context.loopBound
        context.channel.close().whenFailure { error in
          let context = loopBoundContext.value
          context.fireErrorCaught(error)
        }
      }
      context.fireUserInboundEventTriggered(event)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
      let accepted = Self.unwrapInboundIn(data)
      let ctxEventLoop = context.eventLoop
      let childEventLoop = accepted.eventLoop
      let childChannelInit =
        self.childChannelInit ?? { (_: Channel) in childEventLoop.makeSucceededFuture(()) }

      @inline(__always)
      @Sendable
      func setupChildChannel() -> EventLoopFuture<Void> {
        childEventLoop.assertInEventLoop()
        return childChannelInit(accepted)
      }

      @inline(__always)
      func fireThroughPipeline(_ future: EventLoopFuture<Void>, context: ChannelHandlerContext) {
        // Strictly these asserts are redundant with future.assumeIsolated(), but as this code
        // has guarantees that can be quite hard to follow we keep them here.
        ctxEventLoop.assertInEventLoop()
        assert(ctxEventLoop === context.eventLoop)
        future.assumeIsolated().flatMap { (_) -> EventLoopFuture<Void> in
          guard context.channel.isActive else {
            return ctxEventLoop.makeFailedFuture(ChannelError.ioOnClosedChannel)
          }
          context.fireChannelRead(Self.wrapInboundOut(accepted))
          return context.eventLoop.makeSucceededFuture(())
        }.whenFailure { error in
          self.closeAndFire(context: context, accepted: accepted, err: error)
        }
      }

      if childEventLoop === ctxEventLoop {
        fireThroughPipeline(setupChildChannel(), context: context)
      } else {
        fireThroughPipeline(
          childEventLoop.flatSubmit {
            setupChildChannel()
          }.hop(to: ctxEventLoop),
          context: context
        )
      }
    }

    private func closeAndFire(context: ChannelHandlerContext, accepted: LwIPPCBChannel, err: Error)
    {
      accepted.close(promise: nil)
      if context.eventLoop.inEventLoop {
        context.fireErrorCaught(err)
      } else {
        let loopBoundContext = context.loopBound
        context.eventLoop.execute {
          let context = loopBoundContext.value
          context.fireErrorCaught(err)
        }
      }
    }
  }
}

extension Channel {

  fileprivate func registerAndDoSynchronously(
    _ body: @escaping (Channel) -> EventLoopFuture<Void>
  ) -> EventLoopFuture<Void> {
    // this is pretty delicate at the moment:
    // In many cases `body` must be _synchronously_ follow `register`, otherwise in our current
    // implementation, `epoll` will send us `EPOLLHUP`. To have it run synchronously, we need to invoke the
    // `flatMap` on the eventloop that the `register` will succeed on.
    self.eventLoop.assertInEventLoop()
    return self.register().assumeIsolated().flatMap {
      body(self)
    }.nonisolated()
  }
}

extension Address {

  fileprivate var address: SocketAddress {
    get throws {
      let resolved: SocketAddress
      switch self {
      case .hostPort(let host, let port):
        switch host {
        case .ipv4(let ipaddr):
          resolved = try SocketAddress(
            packedIPAddress: ByteBuffer(bytes: ipaddr.rawValue),
            port: Int(port.rawValue)
          )
        case .ipv6(let ipaddr):
          resolved = try SocketAddress(
            packedIPAddress: ByteBuffer(bytes: ipaddr.rawValue),
            port: Int(port.rawValue)
          )
        case .name(let name):
          resolved = try SocketAddress.makeAddressResolvingHost(name, port: Int(port.rawValue))
        }
      case .unix(let path):
        resolved = try SocketAddress(unixDomainSocketPath: path)
      case .url(let url):
        throw SocketAddressError.unsupported
      }
      return resolved
    }
  }
}
