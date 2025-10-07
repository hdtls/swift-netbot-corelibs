//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import AnlzrReports
import Logging
import NIOCore

#if canImport(Network)
  import Network
  import NIOTransportServices
#else
  import NIOPosix
#endif

/// `ForwardProtocolDirect` will send proxied rerquest to the endpoint derectly.
@available(SwiftStdlib 5.3, *)
public struct ForwardProtocolDirect: Equatable, Hashable, Sendable {

  public var name: String

  public init(name: String = "DIRECT") {
    self.name = name
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolDirect: ForwardProtocol {

  public func makeConnection(logger: Logger, connection: Connection, on eventLoop: any EventLoop)
    async throws -> any Channel
  {
    guard let destination = connection.originalRequest?.address else {
      throw AnlzrError.outputStreamEndpointInvalid
    }

    let bootstrap = ClientBootstrap(group: eventLoop)
    #if canImport(Network)
      _ = bootstrap.configureNWParameters {
        $0.preferNoProxies = true
      }
    #endif
    return
      try await bootstrap
      .channelOption(.tcpOption(.tcp_nodelay), value: 1)
      .connect(to: destination) { channel in
        channel.eventLoop.makeSucceededFuture(channel)
      }
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolDirect: ForwardProtocolConvertible {}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocol where Self == ForwardProtocolDirect {

  /// Return the default `ForwardProtocolDirect`.
  public static var direct: ForwardProtocolDirect {
    ForwardProtocolDirect()
  }
}

@available(SwiftStdlib 5.3, *)
extension ForwardProtocolConvertible where Self == ForwardProtocolDirect {

  /// Return the default `ForwardProtocolDirect`.
  public static var direct: ForwardProtocolDirect {
    ForwardProtocolDirect()
  }
}
