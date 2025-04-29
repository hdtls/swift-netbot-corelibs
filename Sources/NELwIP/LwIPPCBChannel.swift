//
// See LICENSE.txt for license information
//

import Atomics
import CNELwIP
import NIOConcurrencyHelpers
import NIOCore
import Logging

private struct LwIPChannelLifecycleManager {
  // MARK: Types
  private enum State {
    case fresh
    case preRegistered  // register() has been run but the selector doesn't know about it yet
    case fullyRegistered  // fully registered, ie. the selector knows about it
    case activated
    case closed
  }

  private enum Event {
    case activate
    case beginRegistration
    case finishRegistration
    case close
  }

  // MARK: properties
  private let eventLoop: EventLoop
  // this is queried from the Channel, ie. must be thread-safe
  internal let isActiveAtomic: ManagedAtomic<Bool>
  // these are only to be accessed on the EventLoop

  // have we seen the `.readEOF` notification
  // note: this can be `false` on a deactivated channel, we might just have torn it down.
  var hasSeenEOFNotification: Bool = false

  // Should we support transition from `active` to `active`, used by datagram sockets.
  let supportsReconnect: Bool

  private var currentState: State = .fresh {
    didSet {
      self.eventLoop.assertInEventLoop()
      switch (oldValue, self.currentState) {
      case (_, .activated):
        self.isActiveAtomic.store(true, ordering: .relaxed)
      case (.activated, _):
        self.isActiveAtomic.store(false, ordering: .relaxed)
      default:
        ()
      }
    }
  }

  // MARK: API
  // isActiveAtomic needs to be injected as it's accessed from arbitrary threads and `SocketChannelLifecycleManager` is usually held mutable
  internal init(
    eventLoop: EventLoop,
    isActiveAtomic: ManagedAtomic<Bool>,
    supportReconnect: Bool
  ) {
    self.eventLoop = eventLoop
    self.isActiveAtomic = isActiveAtomic
    self.supportsReconnect = supportReconnect
  }

  // this is called from Channel's deinit, so don't assert we're on the EventLoop!
  internal var canBeDestroyed: Bool {
    self.currentState == .closed
  }

  // we need to return a closure here and to not suffer from a potential allocation for that this must be inlined
  @inline(__always)
  internal mutating func beginRegistration() -> ((EventLoopPromise<Void>?, ChannelPipeline) -> Void)
  {
    self.moveState(event: .beginRegistration)
  }

  // we need to return a closure here and to not suffer from a potential allocation for that this must be inlined
  @inline(__always)
  internal mutating func finishRegistration() -> (
    (EventLoopPromise<Void>?, ChannelPipeline) -> Void
  ) {
    self.moveState(event: .finishRegistration)
  }

  // we need to return a closure here and to not suffer from a potential allocation for that this must be inlined
  @inline(__always)
  internal mutating func close() -> ((EventLoopPromise<Void>?, ChannelPipeline) -> Void) {
    self.moveState(event: .close)
  }

  // we need to return a closure here and to not suffer from a potential allocation for that this must be inlined
  @inline(__always)
  internal mutating func activate() -> ((EventLoopPromise<Void>?, ChannelPipeline) -> Void) {
    self.moveState(event: .activate)
  }

  // MARK: private API
  // we need to return a closure here and to not suffer from a potential allocation for that this must be inlined
  @inline(__always)
  private mutating func moveState(event: Event) -> (
    (EventLoopPromise<Void>?, ChannelPipeline) -> Void
  ) {
    self.eventLoop.assertInEventLoop()

    switch (self.currentState, event) {
    // origin: .fresh
    case (.fresh, .beginRegistration):
      self.currentState = .preRegistered
      return { promise, pipeline in
        promise?.succeed(())
        pipeline.syncOperations.fireChannelRegistered()
      }

    case (.fresh, .close):
      self.currentState = .closed
      return { (promise, _: ChannelPipeline) in
        promise?.succeed(())
      }

    // origin: .preRegistered
    case (.preRegistered, .finishRegistration):
      self.currentState = .fullyRegistered
      return { (promise, _: ChannelPipeline) in
        promise?.succeed(())
      }

    // origin: .fullyRegistered
    case (.fullyRegistered, .activate):
      self.currentState = .activated
      return { promise, pipeline in
        promise?.succeed(())
        pipeline.syncOperations.fireChannelActive()
      }

    // origin: .preRegistered || .fullyRegistered
    case (.preRegistered, .close), (.fullyRegistered, .close):
      self.currentState = .closed
      return { promise, pipeline in
        promise?.succeed(())
        pipeline.syncOperations.fireChannelUnregistered()
      }

    // origin: .activated
    case (.activated, .close):
      self.currentState = .closed
      return { promise, pipeline in
        promise?.succeed(())
        pipeline.syncOperations.fireChannelInactive()
        pipeline.syncOperations.fireChannelUnregistered()
      }

    // origin: .activated
    case (.activated, .activate) where self.supportsReconnect:
      return { promise, pipeline in
        promise?.succeed(())
      }

    // bad transitions
    case (.fresh, .activate),  // should go through .registered first
      (.preRegistered, .activate),  // need to first be fully registered
      (.preRegistered, .beginRegistration),  // already registered
      (.fullyRegistered, .beginRegistration),  // already registered
      (.activated, .activate),  // already activated
      (.activated, .beginRegistration),  // already fully registered (and activated)
      (.activated, .finishRegistration),  // already fully registered (and activated)
      (.fullyRegistered, .finishRegistration),  // already fully registered
      (.fresh, .finishRegistration),  // need to register lazily first
      (.closed, _):  // already closed
      self.badTransition(event: event)
    }
  }

  private func badTransition(event: Event) -> Never {
    preconditionFailure("illegal transition: state=\(self.currentState), event=\(event)")
  }

  // MARK: convenience properties
  internal var isActive: Bool {
    self.eventLoop.assertInEventLoop()
    return self.currentState == .activated
  }

  internal var isPreRegistered: Bool {
    self.eventLoop.assertInEventLoop()
    switch self.currentState {
    case .fresh, .closed:
      return false
    case .preRegistered, .fullyRegistered, .activated:
      return true
    }
  }

  internal var isRegisteredFully: Bool {
    self.eventLoop.assertInEventLoop()
    switch self.currentState {
    case .fresh, .closed, .preRegistered:
      return false
    case .fullyRegistered, .activated:
      return true
    }
  }

  /// Returns whether the underlying file descriptor is open. This property will always be true (even before registration)
  /// until the Channel is closed.
  internal var isOpen: Bool {
    self.eventLoop.assertInEventLoop()
    return self.currentState != .closed
  }
}

class BaseLwIPPCBChannel<LwIPPCB: BaseLwIPPCBProtocol>: Channel, ChannelCore, @unchecked Sendable {

  struct AddressCache {
    // deliberately lets because they must always be updated together (so forcing `init` is useful).
    let local: SocketAddress?
    let remote: SocketAddress?
  }

  internal let socket: LwIPPCB
  private let closePromise: EventLoopPromise<Void>
  private let _eventLoop: any EventLoop
  private let _offEventLoopLock = NIOLock()
  private let isActiveAtomic = ManagedAtomic(false)

  private var _pipeline: ChannelPipeline! = nil

  // please use `self.addressesCached` instead
  private var _addressCache = AddressCache(local: nil, remote: nil)

  // please use `self.bufferAllocatorCached` instead.
  private var _bufferAllocatorCache: ByteBufferAllocator

  var addressesCached: AddressCache {
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

  private var lifecycleManager: LwIPChannelLifecycleManager {
    didSet {
      self.eventLoop.assertInEventLoop()
    }
  }

  var allocator: ByteBufferAllocator {
    self.bufferAllocatorCached
  }

  var closeFuture: EventLoopFuture<Void> {
    closePromise.futureResult
  }

  var pipeline: ChannelPipeline {
    _pipeline
  }

  var localAddress: SocketAddress? {
    self.addressesCached.local
  }

  var remoteAddress: SocketAddress? {
    self.addressesCached.remote
  }

  let parent: (any Channel)?

  var isWritable: Bool { true }

  var isActive: Bool {
    self.isActiveAtomic.load(ordering: .relaxed)
  }

  var isOpen: Bool {
    eventLoop.assertInEventLoop()
    return self.lifecycleManager.isOpen
  }

  var isRegistered: Bool {
    self.eventLoop.assertInEventLoop()
    return self.lifecycleManager.isPreRegistered
  }

  var eventLoop: any EventLoop {
    _eventLoop
  }

  var _channelCore: any ChannelCore { self }

  init(socket: LwIPPCB, parent: Channel?, eventLoop: any EventLoop) {
    eventLoop.assertInEventLoop()
    self.socket = socket
    self.closePromise = eventLoop.makePromise()
    self._eventLoop = eventLoop
    self._bufferAllocatorCache = self.bufferAllocator
    self.parent = parent
    self._addressCache = .init(
      local: try? socket.localAddress(),
      remote: try? socket.remoteAddress()
    )
    self.lifecycleManager = LwIPChannelLifecycleManager(
      eventLoop: eventLoop,
      isActiveAtomic: isActiveAtomic,
      supportReconnect: false
    )
    self._pipeline = ChannelPipeline(channel: self)
  }

  deinit {
    assert(
      self.lifecycleManager.canBeDestroyed,
      "leak of open Channel, state: \(String(describing: self.lifecycleManager))"
    )
    Logger(label: "LwIP").debug("\(self) closed")
  }

  final func updateCachedAddressesFromSocket(updateLocal: Bool = true, updateRemote: Bool = true) {
    self.eventLoop.assertInEventLoop()
    assert(updateLocal || updateRemote)
    let cached = self.addressesCached
    let local = updateLocal ? try? self.localAddress0() : cached.local
    let remote = updateRemote ? try? self.remoteAddress0() : cached.remote
    self.addressesCached = AddressCache(local: local, remote: remote)
  }

  func connectSocket(to address: SocketAddress) throws -> Bool {
    fatalError("this must be overridden by sub class")
  }

  func finishConnectSocket() throws {
    fatalError("this must be overridden by sub class")
  }

  func bufferPendingWrite(data: NIOAny, promise: EventLoopPromise<Void>?) {
    fatalError("this must be overridden by sub class")
  }

  func markFlushPoint() {
    fatalError("this must be overridden by sub class")
  }

  func getOption<Option>(_ option: Option) -> EventLoopFuture<Option.Value>
  where Option: ChannelOption {
    eventLoop.makeFailedFuture(ChannelError.operationUnsupported)
  }

  func setOption<Option>(_ option: Option, value: Option.Value) -> EventLoopFuture<Void>
  where Option: ChannelOption {
    eventLoop.makeFailedFuture(ChannelError.operationUnsupported)
  }

  func localAddress0() throws -> SocketAddress {
    self.eventLoop.assertInEventLoop()
    guard self.isOpen else {
      throw ChannelError.ioOnClosedChannel
    }
    return try self.socket.localAddress()
  }

  func remoteAddress0() throws -> SocketAddress {
    self.eventLoop.assertInEventLoop()
    guard self.isOpen else {
      throw ChannelError.ioOnClosedChannel
    }
    return try self.socket.remoteAddress()
  }

  func register0(promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    guard self.isOpen else {
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    guard !self.lifecycleManager.isPreRegistered else {
      promise?.fail(ChannelError.inappropriateOperationForState)
      return
    }

    self.lifecycleManager.beginRegistration()(promise, self.pipeline)
  }

  func registerAlreadyConfigured0(promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()
    assert(self.isOpen)
    assert(!self.lifecycleManager.isActive)
    let registerPromise = self.eventLoop.makePromise(of: Void.self)
    self.register0(promise: registerPromise)
    registerPromise.futureResult.whenFailure { (_: Error) in
      self.close(promise: nil)
    }
    registerPromise.futureResult.cascadeFailure(to: promise)
    if self.lifecycleManager.isPreRegistered {
      // we expect kqueue/epoll registration to always succeed which is basically true, except for errors that
      // should be fatal (EBADF, EFAULT, ESRCH, ENOMEM) and a two 'table full' (EMFILE, ENFILE) error kinds which
      // we don't handle yet but might do in the future (#469).
      try! becomeFullyRegistered0()
      if self.lifecycleManager.isRegisteredFully {
        self.becomeActive0(promise: promise)
      }
    }
  }

  func bind0(to address: SocketAddress, promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    guard self.isOpen else {
      return
    }

    do {
      try socket.bind(to: address)
      promise?.succeed()
      self.updateCachedAddressesFromSocket(updateRemote: false)
    } catch {
      promise?.fail(error)
    }
  }

  final func connect0(to address: SocketAddress, promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()
    guard self.isOpen else {
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    guard self.lifecycleManager.isPreRegistered else {
      promise?.fail(ChannelError.inappropriateOperationForState)
      return
    }

    do {
      if try !self.connectSocket(to: address) {
        self.updateCachedAddressesFromSocket(updateLocal: true, updateRemote: false)
        try self.becomeFullyRegistered0()
      } else {
        self.updateCachedAddressesFromSocket()
        self.becomeActive0(promise: promise)
      }
    } catch {
      assert(self.lifecycleManager.isPreRegistered)
      promise?.fail(error)
      self.close0(error: error, mode: .all, promise: nil)
    }
  }

  final func write0(_ data: NIOAny, promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()

    guard self.isOpen else {
      // Channel was already closed, fail the promise and not even queue it.
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    bufferPendingWrite(data: data, promise: promise)
  }

  func flush0() {
    eventLoop.assertInEventLoop()
    guard isOpen else {
      return
    }

    guard self.lifecycleManager.isActive else {
      return
    }

    self.markFlushPoint()
  }

  func read0() {
    eventLoop.assertInEventLoop()
  }

  func close0(error: Error, mode: CloseMode, promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    Logger(label: "LwIP").debug("\(error) - \(socket) \(socket.descriptor.pointee.state)")

    guard isOpen else {
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    guard mode == .all else {
      promise?.fail(ChannelError.operationUnsupported)
      return
    }

    let p: EventLoopPromise<Void>?
    do {
      try socket.close()
      p = promise
    } catch {
      pipeline.syncOperations.fireErrorCaught(error)
      p = nil
    }

    let callouts = self.lifecycleManager.close()
    callouts(p, self.pipeline)

    eventLoop.execute {
      self.removeHandlers(pipeline: self.pipeline)
      self.closePromise.succeed()
      self.addressesCached = .init(local: nil, remote: nil)
    }
  }

  func triggerUserOutboundEvent0(_ event: Any, promise: EventLoopPromise<Void>?) {
    promise?.fail(ChannelError.operationUnsupported)
  }

  func channelRead0(_ data: NIOAny) {
    // Do nothing
  }

  func errorCaught0(error: any Error) {
    // Do nothing
  }

  final func becomeFullyRegistered0() throws {
    self.eventLoop.assertInEventLoop()
    assert(self.lifecycleManager.isPreRegistered)
    assert(!self.lifecycleManager.isRegisteredFully)

    self.lifecycleManager.finishRegistration()(nil, self.pipeline)
  }

  final func becomeActive0(promise: EventLoopPromise<Void>?) {
    self.eventLoop.assertInEventLoop()
    assert(self.lifecycleManager.isPreRegistered)
    if !self.lifecycleManager.isRegisteredFully {
      do {
        try self.becomeFullyRegistered0()
        assert(self.lifecycleManager.isRegisteredFully)
      } catch {
        self.close0(error: error, mode: .all, promise: promise)
        return
      }
    }
    self.lifecycleManager.activate()(promise, self.pipeline)
  }
}

final class LwIPPCBChannel: BaseLwIPPCBChannel<LwIPPCB>, @unchecked Sendable {

  override init(socket: LwIPPCB, parent: (any Channel)?, eventLoop: any EventLoop) {
    super.init(socket: socket, parent: parent, eventLoop: eventLoop)
    tcp_arg(socket.descriptor, Unmanaged.passUnretained(self).toOpaque())
    tcp_err(socket.descriptor) { opaquePtr, error in
      guard let opaquePtr else { return }
      guard error == ERR_ABRT || error == ERR_RST || error == ERR_CLSD else { return }
      // When we receive error we should release our connection
      // so .takeRetainedValue() is called, decreases the
      // reference count of the connection.
      let channel = Unmanaged<LwIPPCBChannel>.fromOpaque(opaquePtr).takeUnretainedValue()
      channel.eventLoop.assertInEventLoop()
      channel.pipeline.syncOperations.fireErrorCaught(LwIPError(code: error))
    }
    tcp_recv(socket.descriptor) { opaquePtr, conn, data, error in
      guard error == ERR_OK else { return error }
      guard let opaquePtr else { return ERR_ARG }
      let channel = Unmanaged<LwIPPCBChannel>.fromOpaque(opaquePtr).takeUnretainedValue()
      channel.eventLoop.assertInEventLoop()

      guard let data else {
        channel.pipeline.syncOperations.fireChannelReadComplete()
        return ERR_OK
      }

      var byteBuffer = channel.allocator.buffer(capacity: Int(data.pointee.tot_len))
      var bufferPtr: UnsafeMutablePointer<pbuf>? = data
      while let data = bufferPtr {
        byteBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(data.pointee.tot_len)) {
          Int(pbuf_copy_partial(data, $0.baseAddress, data.pointee.len, 0))
        }
        bufferPtr = data.pointee.next
      }
      tcp_recved(channel.socket.descriptor, UInt16(byteBuffer.readableBytes))
      channel.pipeline.syncOperations.fireChannelRead(NIOAny(byteBuffer))
      return ERR_OK
    }
  }

  override func connectSocket(to address: SocketAddress) throws -> Bool {
    throw ChannelError.operationUnsupported
  }

  override func finishConnectSocket() throws {
    throw ChannelError.operationUnsupported
  }

  override func bufferPendingWrite(data: NIOAny, promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    guard isOpen else {
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    let byteBuffer = unwrapData(data, as: ByteBuffer.self)
    let rt = byteBuffer.withUnsafeReadableBytes {
      tcp_write(socket.descriptor, $0.baseAddress, UInt16($0.count), UInt8(TCP_WRITE_FLAG_COPY))
    }
    switch rt {
    case ERR_OK:
      promise?.succeed()
    case ERR_MEM:
      self.pipeline.syncOperations.fireChannelWritabilityChanged()
      promise?.fail(LwIPError(code: rt))
    default:
      promise?.fail(LwIPError(code: rt))
    }
  }

  override func markFlushPoint() {
    eventLoop.assertInEventLoop()
    tcp_output(socket.descriptor)
  }
}

final class ServerLwIPPCBChannel: BaseLwIPPCBChannel<ServerLwIPPCB>, @unchecked Sendable {

  private var backlog: Int32 = TCP_DEFAULT_LISTEN_BACKLOG

  init(socket: ServerLwIPPCB, eventLoop: any EventLoop) throws {
    try super.init(socket: socket, parent: nil, eventLoop: eventLoop)
    tcp_arg(socket.descriptor, Unmanaged.passUnretained(self).toOpaque())
  }

  convenience init(protocolFamily: NIOBSDSocket.ProtocolFamily, eventLoop: any EventLoop) throws {
    let socket = try ServerLwIPPCB(protocolFamily: protocolFamily)
    try self.init(socket: socket, eventLoop: eventLoop)
  }

  convenience init(eventLoop: any EventLoop) throws {
    try self.init(protocolFamily: .inet, eventLoop: eventLoop)
  }

  override func connectSocket(to address: SocketAddress) throws -> Bool {
    throw ChannelError.operationUnsupported
  }

  override func finishConnectSocket() throws {
    throw ChannelError.operationUnsupported
  }

  override func bufferPendingWrite(data: NIOAny, promise: EventLoopPromise<Void>?) {
    promise?.fail(ChannelError.operationUnsupported)
  }

  override func bind0(to address: SocketAddress, promise: EventLoopPromise<Void>?) {
    eventLoop.assertInEventLoop()

    guard self.isOpen else {
      promise?.fail(ChannelError.ioOnClosedChannel)
      return
    }

    guard self.isRegistered else {
      promise?.fail(ChannelError.inappropriateOperationForState)
      return
    }

    let p = eventLoop.makePromise(of: Void.self)
    p.futureResult.map {
      self.becomeActive0(promise: promise)
    }.cascadeFailure(to: promise)

    do {
      try socket.bind(to: address)
      updateCachedAddressesFromSocket(updateRemote: false)
      try socket.listen(backlog: backlog)
      // Socket.descriptor may changed after listen(backlog:) called,
      // We should register listener after
      tcp_accept(socket.descriptor) { contextPtr, connection, error in
        guard error == ERR_OK else { return error }
        guard let contextPtr else { return ERR_ABRT }
        // Returns `ERR_MEM` is connection is nil, see `tcp_input` for details.
        guard let connection else { return ERR_MEM }
        let channel = Unmanaged<ServerLwIPPCBChannel>
          .fromOpaque(contextPtr)
          .takeUnretainedValue()
        channel.eventLoop.assertInEventLoop()

        let socket = LwIPPCB(socket: connection)
        let childChannel = LwIPPCBChannel(
          socket: socket,
          parent: nil,
          eventLoop: channel.eventLoop
        )
        channel.pipeline.syncOperations.fireChannelRead(NIOAny(childChannel))
        return error
      }
      p.succeed()
    } catch {
      p.fail(error)
    }
  }

  override func channelRead0(_ data: NIOAny) {
    self.eventLoop.assertInEventLoop()

    let ch = self.unwrapData(data, as: LwIPPCBChannel.self)
    ch.eventLoop.execute {
      ch.register().flatMapThrowing {
        guard ch.isOpen else {
          throw ChannelError.ioOnClosedChannel
        }
        ch.becomeActive0(promise: nil)
      }.whenFailure { error in
        ch.close(promise: nil)
      }
    }
  }
}
