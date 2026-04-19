//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import CoWOptimization
import HTTPTypes
import Logging
import NEAddressProcessing
import NEVMESS
import NIOCore
import NIOHTTP1
import NIOTLS
import NIOWebSocket
import NetbotLite
import NetbotLiteData
import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif
#if canImport(Network)
  import Network
  import NIOTransportServices
#else
  import NIOPosix
  import NIOSSL
#endif

@available(SwiftStdlib 5.7, *)
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

@available(SwiftStdlib 5.7, *)
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

@available(SwiftStdlib 5.7, *)
extension ForwardProtocolVMESS._Storage: @unchecked Sendable {}

@available(SwiftStdlib 5.7, *)
extension ForwardProtocolVMESS: ProxiableForwardProtocol {

  func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    guard let destinationAddress = connection.originalRequest?.address else {
      throw SocketAddressError.unsupported
    }

    let validPortRange = Int(UInt16.min)...Int(UInt16.max)
    guard validPortRange.contains(port) else {
      throw AnalyzeError.outputStreamEndpointInvalid
    }

    let destination = Address.hostPort(
      host: .init(serverAddress),
      port: .init(rawValue: UInt16(port))
    )

    var finalize: EventLoopFuture<any Channel>

    var options = TLSConfiguration.makeClientConfiguration()
    options.applicationProtocols = ["http/1.1"]
    let tls = try NEClientTLSProvider<ClientBootstrap>(
      options: options,
      sni: tlsOptions.sni.isEmpty ? nil : tlsOptions.sni
    )
    let bootstrap = ClientBootstrap(group: eventLoop.next())
    #if canImport(Network)
      _ = bootstrap.configureNWParameters {
        $0.preferNoProxies = true
      }
    #endif

    let (channel, alpn) =
      try await NIOClientTCPBootstrap(bootstrap, tls: tls)
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
        var headers = HTTPHeaders()
        if let additionalHTTPFields = ws.additionalHTTPFields {
          for field in additionalHTTPFields {
            headers.replaceOrAdd(name: field.name.rawName, value: field.value)
          }
        }
        headers.add(name: "Host", value: "\(destination)")

        finalize = try await channel.pipeline.configureUpgradableHTTPClientPipeline(
          configuration: .init(
            upgradeConfiguration: .init(
              upgradeRequestHead: HTTPRequestHead(
                version: .http1_1,
                method: .GET,
                uri: ws.uri,
                headers: headers
              ),
              upgraders: [
                NIOTypedWebSocketClientUpgrader { channel, response in
                  channel.pipeline.addHandler(WebSocketFrameAggregator())
                    .map { channel }
                }
              ],
              notUpgradingCompletionHandler: { channel in
                channel.close().flatMap {
                  channel.eventLoop.makeFailedFuture(AnalyzeError.connectionRefused)
                }
              }
            )
          )
        )
        .get()

        // Walkaround for
        channel.pipeline.fireChannelActive()

        _ = try await finalize.get()
      }

      finalize = try await channel.configureVMESSConnectionPipeline(
        contentSecurity: .aes128Gcm,
        user: userID,
        destinationAddress: destinationAddress
      ) {
        channel.eventLoop.makeSucceededFuture(channel)
      }
      .get()
    case .negotiated(let token):
      throw ALPNError.negotiatedTokenUnsupported(token)
    }

    return try await finalize.get()
  }
}

@available(SwiftStdlib 5.7, *)
extension ForwardProtocolVMESS: ForwardProtocolConvertible {}
