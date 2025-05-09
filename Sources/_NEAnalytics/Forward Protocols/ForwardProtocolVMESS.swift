//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import CoWOptimization
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
#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@_cowOptimization struct ForwardProtocolVMESS: Hashable, Sendable {

  var name: String

  var serverAddress: String

  var port: Int

  var userID: UUID

  var ws: AnyProxy.WebSocket

  var tls: AnyProxy.TLS

  var tlsOptions: AnyProxy.TLS {
    tls
  }

  init(
    name: String, serverAddress: String, port: Int, userID: UUID, ws: AnyProxy.WebSocket,
    tls: AnyProxy.TLS
  ) {
    self._storage = _Storage(
      name: name, serverAddress: serverAddress, port: port, userID: userID, ws: ws, tls: tls)
  }
}

extension ForwardProtocolVMESS._Storage: Hashable {
  static func == (lhs: ForwardProtocolVMESS._Storage, rhs: ForwardProtocolVMESS._Storage) -> Bool {
    return lhs.name == rhs.name
      && lhs.serverAddress == rhs.serverAddress
      && lhs.port == rhs.port
      && lhs.userID == rhs.userID
      && lhs.ws == rhs.ws
      && lhs.tls == rhs.tls
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(serverAddress)
    hasher.combine(port)
    hasher.combine(userID)
    hasher.combine(ws)
    hasher.combine(tls)
  }
}

extension ForwardProtocolVMESS._Storage: @unchecked Sendable {}

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
        finalize = try await channel.configureVMESSPipeline(
          contentSecurity: .aes128Gcm,
          user: userID,
          destinationAddress: destinationAddress
        ) {
          channel.eventLoop.makeSucceededFuture(channel)
        }
        .get()
      }
    case .negotiated(let token):
      throw ALPNError.negotiatedTokenUnsupported(token)
    }

    return try await finalize.get()
  }
}

extension ForwardProtocolVMESS: ForwardProtocolConvertible {}
