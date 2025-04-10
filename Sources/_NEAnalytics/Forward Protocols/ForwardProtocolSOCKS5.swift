//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Logging
import NEAddressProcessing
import NESOCKS
import NIOCore
import NIOTLS
import _ResourceProcessing

struct ForwardProtocolSOCKS5: Equatable, Hashable, Sendable {

  @usableFromInline final class _Storage: Hashable, @unchecked Sendable {
    @usableFromInline var name: String
    @usableFromInline var serverAddress: String
    @usableFromInline var port: Int
    @usableFromInline var username: String
    @usableFromInline var passwordReference: String
    @usableFromInline var authenticationRequired: Bool
    @usableFromInline var tls: AnyProxy.TLS

    @inlinable init(
      name: String, serverAddress: String, port: Int,
      username: String, passwordReference: String, authenticationRequired: Bool,
      tls: AnyProxy.TLS
    ) {
      self.name = name
      self.serverAddress = serverAddress
      self.port = port
      self.username = username
      self.passwordReference = passwordReference
      self.authenticationRequired = authenticationRequired
      self.tls = tls
    }

    @inlinable func copy() -> _Storage {
      _Storage(
        name: name,
        serverAddress: serverAddress,
        port: port,
        username: username,
        passwordReference: passwordReference,
        authenticationRequired: authenticationRequired,
        tls: tls
      )
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
      return lhs.name == rhs.name && lhs.serverAddress == rhs.serverAddress && lhs.port == rhs.port
        && lhs.username == rhs.username && lhs.passwordReference == rhs.passwordReference
        && lhs.authenticationRequired == rhs.authenticationRequired && lhs.tls == rhs.tls
    }

    @inlinable func hash(into hasher: inout Hasher) {
      hasher.combine(name)
      hasher.combine(serverAddress)
      hasher.combine(port)
      hasher.combine(username)
      hasher.combine(passwordReference)
      hasher.combine(authenticationRequired)
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

  @inlinable var username: String {
    get { _storage.username }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.username = newValue
    }
  }

  @inlinable var passwordReference: String {
    get { _storage.passwordReference }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.passwordReference = newValue
    }
  }

  @inlinable var authenticationRequired: Bool {
    get { _storage.authenticationRequired }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.authenticationRequired = newValue
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
    name: String,
    serverAddress: String,
    port: Int,
    username: String,
    passwordReference: String,
    authenticationRequired: Bool,
    tls: AnyProxy.TLS
  ) {
    _storage = _Storage(
      name: name,
      serverAddress: serverAddress,
      port: port,
      username: username,
      passwordReference: passwordReference,
      authenticationRequired: authenticationRequired,
      tls: tls
    )
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }
}

extension ForwardProtocolSOCKS5: ProxiableForwardProtocol {

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
      finalize = channel.configureSOCKS5Pipeline(
        username: username,
        passwordReference: passwordReference,
        authenticationRequired: authenticationRequired,
        destinationAddress: destinationAddress
      )
      .map { channel }
    case .negotiated(let token):
      finalize = channel.close().flatMap {
        channel.eventLoop.makeFailedFuture(ALPNError.negotiatedTokenUnsupported(token))
      }
    }

    return try await finalize.get()
  }
}

extension ForwardProtocolSOCKS5: ForwardProtocolConvertible {}
