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

import Atomics
import Dispatch
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
class BaseSocketChannel<SocketType: BaseSocketProtocol>: Channel, ChannelCore, @unchecked Sendable {

  internal let socket: SocketType

  struct AddressCache {
    // deliberately lets because they must always be updated together (so forcing `init` is useful).
    let local: SocketAddress?
    let remote: SocketAddress?
  }

  let eventLoop: any EventLoop
  private let closePromise: EventLoopPromise<Void>

  internal let _offEventLoopLock = NIOLock()

  // please use `self.addressesCached` instead.
  private var _addressCache = AddressCache(local: nil, remote: nil)

  // This is called from arbitrary threads.
  internal var addressesCached: AddressCache {
    get {
      if self.eventLoop.inEventLoop {
        return self._addressCache
      } else {
        return self._offEventLoopLock.withLock {
          self._addressCache
        }
      }
    }
    set {
      self.eventLoop.preconditionInEventLoop()
      self._offEventLoopLock.withLock {
        self._addressCache = newValue
      }
    }
  }

  // please use `self.bufferAllocatorCached` instead.
  private var _bufferAllocatorCache: ByteBufferAllocator

  private var bufferAllocatorCached: ByteBufferAllocator {
    get {
      if self.eventLoop.inEventLoop {
        return self._bufferAllocatorCache
      } else {
        return self._offEventLoopLock.withLock {
          self._bufferAllocatorCache
        }
      }
    }
    set {
      self.eventLoop.preconditionInEventLoop()
      self._offEventLoopLock.withLock {
        self._bufferAllocatorCache = newValue
      }
    }
  }

  private var bufferAllocator: ByteBufferAllocator = ByteBufferAllocator() {
    didSet {
      self.eventLoop.assertInEventLoop()
      self.bufferAllocatorCached = self.bufferAllocator
    }
  }

  private var _pipeline: ChannelPipeline! = nil

  private var autoRead = true

  private let _isActive = ManagedAtomic(false)

  private let _isOpen = ManagedAtomic(true)

  private var isFlushPending = false

  final var localAddress: SocketAddress? {
    self.addressesCached.local
  }

  final var remoteAddress: SocketAddress? {
    self.addressesCached.remote
  }

  var parent: (any Channel)?

  var readPending = false

  var isWritable: Bool {
    true
  }

  var isActive: Bool {
    self._isActive.load(ordering: .relaxed)
  }

  final var _channelCore: any ChannelCore { self }

  var isOpen: Bool {
    self.eventLoop.assertInEventLoop()
    return self._isOpen.load(ordering: .relaxed)
  }

  final var closeFuture: EventLoopFuture<Void> {
    self.closePromise.futureResult
  }

  final var allocator: ByteBufferAllocator {
    self.bufferAllocatorCached
  }

  // This is `Channel` API so must be thread-safe.
  final var pipeline: ChannelPipeline {
    self._pipeline
  }

  init(
    socket: SocketType,
    eventLoop: any EventLoop
  ) {
    self.socket = socket
    self.eventLoop = eventLoop
    self.closePromise = eventLoop.makePromise()
    self._bufferAllocatorCache = self.bufferAllocator
    self._pipeline = ChannelPipeline(channel: self)
    self._addressCache = AddressCache(
      local: try? socket.localAddress(),
      remote: try? socket.remoteAddress()
    )
  }

  final func localAddress0() throws -> SocketAddress {
    self.eventLoop.assertInEventLoop()
    guard self.isOpen else {
      throw ChannelError.ioOnClosedChannel
    }
    return try self.socket.localAddress()
  }

  final func remoteAddress0() throws -> SocketAddress {
    self.eventLoop.assertInEventLoop()
    guard self.isOpen else {
      throw ChannelError.ioOnClosedChannel
    }
    return try self.socket.remoteAddress()
  }

  func setOption<Option>(_ option: Option, value: Option.Value) -> EventLoopFuture<Void>
  where Option: ChannelOption {
    self.eventLoop.makeFailedFuture(ChannelError.operationUnsupported)
  }

  func getOption<Option>(_ option: Option) -> EventLoopFuture<Option.Value>
  where Option: ChannelOption {
    self.eventLoop.makeFailedFuture(ChannelError.operationUnsupported)
  }

  func bind0(to address: SocketAddress, promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()

    guard self.isOpen else {
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    do {
      try self.socket.bind(to: address)
      let cached = self.addressesCached
      self.addressesCached = .init(local: try? self.localAddress0(), remote: cached.remote)
      promise?.succeed()
    } catch {
      promise?.fail(error)
    }
  }

  func close0(error: Error, mode: CloseMode, promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()

    guard self.isOpen else {
      promise?.fail(ChannelError.alreadyClosed)
      return
    }

    guard mode == .all else {
      promise?.fail(ChannelError.operationUnsupported)
      return
    }

    do {
      try self.socket.close()
      promise?.succeed()
    } catch {
      promise?.fail(error)
    }

    self._isOpen.store(false, ordering: .relaxed)

    eventLoop.assumeIsolated().execute {
      self.removeHandlers(pipeline: self.pipeline)

      self.closePromise.succeed()

      // Now reset the addresses as we notified all handlers / futures.
      self.addressesCached = .init(local: nil, remote: nil)
    }
  }

  func register0(promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()

    if !self.isOpen {
      promise?.fail(ChannelError.ioOnClosedChannel)
    }

    self.pipeline.fireChannelRegistered()
    promise?.succeed()
  }

  final func registerAlreadyConfigured0(promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()
    assert(self.isOpen)
    assert(!self.isActive)
    let registerPromise = self.eventLoop.makePromise(of: Void.self)
    self.register0(promise: registerPromise)
    registerPromise.futureResult
      .hop(to: self.eventLoop)
      .assumeIsolated()
      .whenFailure { (_: Error) in
        self.close(promise: nil)
      }
    registerPromise.futureResult.cascadeFailure(to: promise)
    self.becomeActive0(promise: promise)
  }

  func connect0(to: SocketAddress, promise: EventLoopPromise<Void>?) {
    promise?.fail(ChannelError.operationUnsupported)
  }

  final func write0(_ data: NIOAny, promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()

    guard self.isOpen else {
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    self.bufferPendingWrite(data: data, promise: promise)
  }

  final func flush0() {
    self.eventLoop.assertInEventLoop()

    guard self.isOpen else {
      return
    }

    self.markFlushPoint()

    self.flushNow()
  }

  func read0() {
    self.eventLoop.assertInEventLoop()

    guard self.isOpen else {
      return
    }
    self.readPending = true
  }

  func triggerUserOutboundEvent0(_ event: Any, promise: EventLoopPromise<Void>?) {
    promise?.fail(ChannelError.operationUnsupported)
  }

  func channelRead0(_ data: NIOAny) {

  }

  func errorCaught0(error: any Error) {

  }

  final func becomeActive0(promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()
    self._isActive.store(true, ordering: .relaxed)
    promise?.succeed()
    self.pipeline.fireChannelActive()
    self.flushNow()
    self.readIfNeeded0()
  }

  enum ReadResult {
    /// Nothing was read by the read operation.
    case none

    /// Some data was read by the read operation.
    case some
  }

  @discardableResult
  func readFromSocket() throws -> ReadResult {
    fatalError("this must be overridden by sub class")
  }

  @discardableResult
  func readIfNeeded0() -> Bool {
    self.eventLoop.assertInEventLoop()
    if !self.isActive {
      return false
    }

    if !self.readPending && self.autoRead {
      self.pipeline.syncOperations.read()
    }
    return self.readPending
  }

  func flushNow() {
    self.eventLoop.assertInEventLoop()

    guard !self.isFlushPending else {
      return
    }
    self.isFlushPending = true
    defer {
      self.isFlushPending = false
    }

    while self.hasFlushedPendingWrites() && self.isOpen, self.isWritable {
      do {
        try self.writeToSocket()
      } catch {
        self.close0(error: error, mode: .all, promise: nil)
      }
    }
  }

  func writeToSocket() throws {
    fatalError("must be overridden")
  }

  /// Returns if there are any flushed, pending writes to be sent over the network.
  func hasFlushedPendingWrites() -> Bool {
    fatalError("this must be overridden by sub class")
  }

  /// Buffer a write in preparation for a flush.
  func bufferPendingWrite(data: NIOAny, promise: EventLoopPromise<Void>?) {
    fatalError("this must be overridden by sub class")
  }

  /// Mark a flush point. This is called when flush is received, and instructs
  /// the implementation to record the flush.
  func markFlushPoint() {
    fatalError("this must be overridden by sub class")
  }
}
