//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Logging
import NEAddressProcessing
import NEVMESS
import NIOCore
import NIOHTTP1
import NIOTLS
import NIOWebSocket
import _ResourceProcessing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

struct ForwardProtocolVMESS: Equatable, Hashable {

  @usableFromInline final class _Storage: Hashable {
    @usableFromInline var name: String
    @usableFromInline var serverAddress: String
    @usableFromInline var port: Int
    @usableFromInline var userID: UUID
    @usableFromInline var ws: AnyProxy.WebSocket
    @usableFromInline var tls: AnyProxy.TLS

    @inlinable init(
      name: String, serverAddress: String, port: Int, userID: UUID,
      ws: AnyProxy.WebSocket, tls: AnyProxy.TLS
    ) {
      self.name = name
      self.serverAddress = serverAddress
      self.port = port
      self.userID = userID
      self.ws = ws
      self.tls = tls
    }

    @inlinable func copy() -> _Storage {
      _Storage(
        name: name, serverAddress: serverAddress, port: port, userID: userID, ws: ws, tls: tls)
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
      return lhs.name == rhs.name
        && lhs.serverAddress == rhs.serverAddress
        && lhs.port == rhs.port
        && lhs.userID == rhs.userID
        && lhs.ws == rhs.ws
        && lhs.tls == rhs.tls
    }

    @inlinable func hash(into hasher: inout Hasher) {
      hasher.combine(name)
      hasher.combine(serverAddress)
      hasher.combine(port)
      hasher.combine(userID)
      hasher.combine(ws)
      hasher.combine(tls)
    }
  }

  @usableFromInline var _storage: _Storage

  @inlinable var name: String {
    get { _storage.name }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.name = newValue
    }
  }

  @inlinable var serverAddress: String {
    get { _storage.serverAddress }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.serverAddress = newValue
    }
  }

  @inlinable var port: Int {
    get { _storage.port }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.port = newValue
    }
  }

  @inlinable var userID: UUID {
    get { _storage.userID }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.userID = newValue
    }
  }

  @inlinable var ws: AnyProxy.WebSocket {
    get { _storage.ws }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.ws = newValue
    }
  }

  @inlinable var tls: AnyProxy.TLS {
    get { _storage.tls }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.tls = newValue
    }
  }

  @inlinable var tlsOptions: AnyProxy.TLS {
    tls
  }

  @inlinable init(
    name: String, serverAddress: String, port: Int, userID: UUID, ws: AnyProxy.WebSocket,
    tls: AnyProxy.TLS
  ) {
    self._storage = _Storage(
      name: name, serverAddress: serverAddress, port: port, userID: userID, ws: ws, tls: tls)
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }
}

extension ForwardProtocolVMESS: @unchecked Sendable {}

extension ForwardProtocolVMESS: ProxiableForwardProtocol {

  func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    guard let destinationAddress = connection.originalRequest.address else {
      throw SocketAddressError.unsupported
    }

    let validPortRange = Int(UInt16.min)...Int(UInt16.max)
    guard validPortRange.contains(port) else {
      throw AnlzrError.outputStreamEndpointInvalid
    }

    let destination = Address.hostPort(
      host: .init(serverAddress),
      port: .init(rawValue: UInt16(port))
    )

    let finalize: EventLoopFuture<any Channel>

    var options = TLSConfiguration.makeClientConfiguration()
    options.applicationProtocols = ["http/1.1"]
    let tls = try NEClientTLSProvider<ClientBootstrap>(
      options: options,
      sni: tlsOptions.sni.isEmpty ? nil : tlsOptions.sni
    )
    let bootstrap = NIOClientTCPBootstrap(ClientBootstrap(group: eventLoop.next()), tls: tls)

    let (channel, alpn) =
      try await bootstrap
      .enableTLS(tlsOptions.isEnabled)
      .connect(to: destination) { channel in
        channel.eventLoop.makeCompletedFuture {
          let finalize: EventLoopFuture<(any Channel, ALPNResult)>
          if tlsOptions.isEnabled {
            let alpnHandler = AsyncALPNHandler { alpn, channel in
              channel.eventLoop.makeSucceededFuture((channel, alpn))
            }
            try channel.pipeline.syncOperations.addHandler(alpnHandler)
            finalize = alpnHandler.protocolNegotiationResult
          } else {
            finalize = channel.eventLoop.makeSucceededFuture((channel, .fallback))
          }
          return finalize
        }
      }
      .get()

    switch alpn {
    case .negotiated("http/1.1"), .fallback:
      if ws.isEnabled {
        finalize = try await channel.configureAsyncVMESSTunnelPipeline(
          contentSecurity: .aes128Gcm,
          user: userID,
          destinationAddress: destinationAddress,
          ws: ws
        ) { channel, _ in
          channel.eventLoop.makeSucceededFuture(channel)
        }
        .get()

        // Walkaround for NIOTypedHTTPClientUpgradeHandler it is a bug that request will not send
        // if handler added after channel is active.
        channel.pipeline.fireChannelActive()
      } else {
        finalize = channel.configureVMESSPipeline(
          contentSecurity: .aes128Gcm,
          user: userID,
          destinationAddress: destinationAddress
        ).map { channel }
      }
    case .negotiated(let token):
      throw ALPNError.negotiatedTokenUnsupported(token)
    }

    return try await finalize.get()
  }
}

extension ForwardProtocolVMESS: ForwardProtocolConvertible {}
