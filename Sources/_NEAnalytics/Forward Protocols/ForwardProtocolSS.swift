//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization
import Logging
import NEAddressProcessing
import NESS
import NIOCore

#if canImport(Network)
  import Network
  import NIOTransportServices
#else
  import NIOPosix
#endif

@available(SwiftStdlib 5.3, *)
@_cowOptimization struct ForwardProtocolSS: Hashable, Sendable {

  var name: String

  var serverAddress: String

  var port: Int

  var algorithm: NESS.Algorithm

  var passwordReference: String

  init(
    name: String,
    serverAddress: String,
    port: Int,
    algorithm: NESS.Algorithm,
    passwordReference: String
  ) {
    self._storage = _Storage(
      name: name,
      serverAddress: serverAddress,
      port: port,
      algorithm: algorithm,
      passwordReference: passwordReference
    )
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolSS._Storage: Hashable {
  static func == (lhs: ForwardProtocolSS._Storage, rhs: ForwardProtocolSS._Storage) -> Bool {
    return lhs.name == rhs.name && lhs.serverAddress == rhs.serverAddress && lhs.port == rhs.port
      && lhs.algorithm == rhs.algorithm && lhs.passwordReference == rhs.passwordReference
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(serverAddress)
    hasher.combine(port)
    hasher.combine(algorithm)
    hasher.combine(passwordReference)
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolSS._Storage: @unchecked Sendable {}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolSS: ProxiableForwardProtocol {

  func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    guard let destinationAddress = connection.originalRequest?.address else {
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

    let bootstrap = ClientBootstrap(group: eventLoop.next())
    #if canImport(Network)
      _ = bootstrap.configureNWParameters {
        $0.preferNoProxies = true
      }
    #endif
    return try await bootstrap.connect(to: destination) { channel in
      channel.configureSSPipeline(
        algorithm: algorithm,
        passwordReference: passwordReference,
        destinationAddress: destinationAddress
      ) {
        channel.eventLoop.makeSucceededFuture(channel)
      }
    }
    .get()
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolSS: ForwardProtocolConvertible {}
