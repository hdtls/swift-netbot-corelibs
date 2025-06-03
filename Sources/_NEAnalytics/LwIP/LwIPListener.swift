//
// See LICENSE.txt for license information
//

import CNELwIP
import NIOConcurrencyHelpers
import NIOCore

final class LwIPListener: BaseSocketChannel<ServerSocket>, @unchecked Sendable {

  private let group: any EventLoopGroup

  final var newConnectionHandler: (@Sendable (_ connection: LwIPConnection) -> Void)? {
    get {
      if self.eventLoop.inEventLoop {
        return self._newConnectionHandler
      } else {
        return self._offEventLoopLock.withLock {
          self._newConnectionHandler
        }
      }
    }
    set {
      if self.eventLoop.inEventLoop {
        self._newConnectionHandler = newValue
      } else {
        self.eventLoop.execute {
          self._newConnectionHandler = newValue
        }
      }
    }
  }
  private var _newConnectionHandler: (@Sendable (_ connection: LwIPConnection) -> Void)?

  init(eventLoop: any EventLoop, group: any EventLoopGroup) {
    self.group = group
    super.init(socket: ServerSocket(), eventLoop: eventLoop)
  }

  final override func channelRead0(_ data: NIOAny) {
    self.eventLoop.assertInEventLoop()

    let channel = self.unwrapData(data, as: LwIPConnection.self)
    let p: EventLoopPromise<Void> = channel.eventLoop.makePromise()
    channel.registerAlreadyConfigured0(promise: p)
    p.futureResult.whenFailure { (_: Error) in
      channel.close(promise: nil)
    }
  }

  final override func bind0(to address: SocketAddress, promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()

    guard self.isOpen else {
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    let p = self.eventLoop.makePromise(of: Void.self)
    p.futureResult.map {
      self.becomeActive0(promise: promise)
    }.whenFailure { error in
      promise?.fail(error)
    }

    do {
      try self.socket.bind(to: address)
      try self.socket.listen()

      let cached = self.addressesCached
      self.addressesCached = .init(local: try? self.localAddress0(), remote: cached.remote)

      let opaquePtr = Unmanaged.passUnretained(self).toOpaque()
      tcp_arg(self.socket.descriptor, opaquePtr)
      // register0(promise:) is execute before bind0 called, so if we
      // register tcp_accept in register0(promise:) the handler will
      // be reset by socket.listen().
      tcp_accept(self.socket.descriptor) { contextPtr, connection, error in
        guard let contextPtr, let connection else {
          return ERR_ARG
        }

        let listener = Unmanaged<LwIPListener>.fromOpaque(contextPtr).takeUnretainedValue()
        let newConnection = LwIPConnection(
          socket: .init(socket: connection), parent: listener, eventLoop: listener.eventLoop
        )
        listener.pipeline.fireChannelRead(newConnection)
        listener.pipeline.fireChannelReadComplete()
        listener.newConnectionHandler?(newConnection)
        return ERR_OK
      }

      p.succeed()
    } catch {
      p.fail(error)
    }
  }

  final override func hasFlushedPendingWrites() -> Bool {
    false
  }

  final override func markFlushPoint() {
  }
}
