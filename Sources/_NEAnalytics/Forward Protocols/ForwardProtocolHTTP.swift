//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization
import Logging
import NEAddressProcessing
import NEHTTP
import NIOCore
import NIOTLS
import _ResourceProcessing

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@_cowOptimization struct ForwardProtocolHTTP: Hashable, Sendable {

  var name: String

  var serverAddress: String

  var port: Int

  var passwordReference: String

  var authenticationRequired: Bool

  var forceHTTPTunneling: Bool

  var tls: AnyProxy.TLS

  var tlsOptions: AnyProxy.TLS {
    tls
  }

  init(
    name: String, serverAddress: String, port: Int, passwordReference: String,
    authenticationRequired: Bool, forceHTTPTunneling: Bool, tls: AnyProxy.TLS
  ) {
    self._storage = _Storage(
      name: name, serverAddress: serverAddress, port: port, passwordReference: passwordReference,
      authenticationRequired: authenticationRequired, forceHTTPTunneling: forceHTTPTunneling,
      tls: tls
    )
  }
}

extension ForwardProtocolHTTP._Storage: Hashable {
  static func == (lhs: ForwardProtocolHTTP._Storage, rhs: ForwardProtocolHTTP._Storage) -> Bool {
    return lhs.name == rhs.name && lhs.serverAddress == rhs.serverAddress && lhs.port == rhs.port
      && lhs.passwordReference == rhs.passwordReference
      && lhs.authenticationRequired == rhs.authenticationRequired
      && lhs.forceHTTPTunneling == rhs.forceHTTPTunneling
      && lhs.tls == rhs.tls
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(serverAddress)
    hasher.combine(port)
    hasher.combine(passwordReference)
    hasher.combine(authenticationRequired)
    hasher.combine(forceHTTPTunneling)
    hasher.combine(tls)
  }
}

extension ForwardProtocolHTTP._Storage: @unchecked Sendable {}

extension ForwardProtocolHTTP: ProxiableForwardProtocol {

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
      finalize = try await channel.configureHTTPTunnelPipeline(
        authenticationRequired: authenticationRequired,
        passwordReference: passwordReference,
        destinationAddress: destinationAddress
      ) {
        channel.eventLoop.makeSucceededFuture(channel)
      }
      .get()
    case .negotiated(let token):
      finalize = channel.close().flatMap {
        channel.eventLoop.makeFailedFuture(ALPNError.negotiatedTokenUnsupported(token))
      }
    }

    return try await finalize.get()
  }
}

extension ForwardProtocolHTTP: ForwardProtocolConvertible {}
