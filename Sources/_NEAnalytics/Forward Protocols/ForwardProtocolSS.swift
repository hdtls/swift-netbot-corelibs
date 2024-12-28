//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Logging
private import NEAddressProcessing
import NESS
import NIOCore

struct ForwardProtocolSS: Equatable, Hashable {

  @usableFromInline final class _Storage: Hashable {
    @usableFromInline var name: String
    @usableFromInline var serverAddress: String
    @usableFromInline var port: Int
    @usableFromInline var algorithm: NESS.Algorithm
    @usableFromInline var passwordReference: String

    @inlinable init(
      name: String, serverAddress: String, port: Int, algorithm: NESS.Algorithm,
      passwordReference: String
    ) {
      self.name = name
      self.serverAddress = serverAddress
      self.port = port
      self.algorithm = algorithm
      self.passwordReference = passwordReference
    }

    @inlinable func copy() -> _Storage {
      _Storage(
        name: name,
        serverAddress: serverAddress,
        port: port,
        algorithm: algorithm,
        passwordReference: passwordReference
      )
    }

    @inlinable static func == (lhs: _Storage, rhs: _Storage) -> Bool {
      return lhs.name == rhs.name && lhs.serverAddress == rhs.serverAddress && lhs.port == rhs.port
        && lhs.algorithm == rhs.algorithm && lhs.passwordReference == rhs.passwordReference
    }

    @inlinable func hash(into hasher: inout Hasher) {
      hasher.combine(name)
      hasher.combine(serverAddress)
      hasher.combine(port)
      hasher.combine(algorithm)
      hasher.combine(passwordReference)
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

  @inlinable var algorithm: NESS.Algorithm {
    get { _storage.algorithm }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.algorithm = newValue
    }
  }

  @inlinable var passwordReference: String {
    get { _storage.passwordReference }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.passwordReference = newValue
    }
  }

  @inlinable init(
    name: String,
    serverAddress: String,
    port: Int,
    algorithm: NESS.Algorithm,
    passwordReference: String
  ) {
    _storage = _Storage(
      name: name,
      serverAddress: serverAddress,
      port: port,
      algorithm: algorithm,
      passwordReference: passwordReference
    )
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }
}

extension ForwardProtocolSS: @unchecked Sendable {}

extension ForwardProtocolSS: ProxiableForwardProtocol {

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

    let eventLoopGroup = eventLoop.next()

    return try await ClientBootstrap(group: eventLoopGroup)
      .connect(to: destination) { channel in
        channel.configureSSPipeline(
          algorithm: algorithm,
          passwordReference: passwordReference,
          destinationAddress: destinationAddress
        )
        .map { channel }
      }
  }
}

extension ForwardProtocolSS: ForwardProtocolConvertible {}
