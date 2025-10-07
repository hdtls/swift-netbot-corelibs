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

import NEAddressProcessing
import NIOCore

#if canImport(Network)
  import Network
  import NIOTransportServices

  @available(SwiftStdlib 5.3, *)
  public typealias ClientBootstrap = NIOTransportServices.NIOTSConnectionBootstrap

  @available(SwiftStdlib 5.3, *)
  public typealias ServerBootstrap = NIOTransportServices.NIOTSListenerBootstrap

  @available(SwiftStdlib 5.3, *)
  public typealias MultiThreadedEventLoopGroup = NIOTransportServices.NIOTSEventLoopGroup

  @available(SwiftStdlib 5.3, *)
  extension MultiThreadedEventLoopGroup {

    public convenience init(numberOfThreads: Int) {
      self.init(loopCount: numberOfThreads)
    }
  }
#else
  import NIOPosix

  public typealias ClientBootstrap = NIOPosix.ClientBootstrap

  public typealias ServerBootstrap = NIOPosix.ServerBootstrap

  public typealias MultiThreadedEventLoopGroup = NIOPosix.MultiThreadedEventLoopGroup
#endif

@available(SwiftStdlib 5.3, *)
extension ClientBootstrap {

  public func connect<Output>(
    to address: Address,
    channelInitializer: @escaping @Sendable (any Channel) -> EventLoopFuture<Output>
  ) async throws -> Output where Output: Sendable {
    switch address {
    case .hostPort(let host, let port):
      switch host {
      case .name(let name):
        return try await connect(
          host: name,
          port: Int(port.rawValue),
          channelInitializer: channelInitializer
        )
      case .ipv4(let v4):
        let data = ByteBuffer(bytes: v4.rawValue)
        let address = try! SocketAddress(packedIPAddress: data, port: Int(port.rawValue))
        return try await connect(to: address, channelInitializer: channelInitializer)
      case .ipv6(let v6):
        let data = ByteBuffer(bytes: v6.rawValue)
        let address = try! SocketAddress(packedIPAddress: data, port: Int(port.rawValue))
        return try await connect(to: address, channelInitializer: channelInitializer)
      }
    case .unix(let path):
      return try await connect(unixDomainSocketPath: path, channelInitializer: channelInitializer)
    case .url:
      throw AnlzrError.operationUnsupported
    }
  }

  #if canImport(Network)
    public func connect<Output>(
      using connection: NWConnection,
      channelInitializer: @escaping @Sendable (any Channel) -> EventLoopFuture<Output>
    ) async throws -> Output where Output: Sendable {
      try await withExistingNWConnection(connection, channelInitializer: channelInitializer)
    }
  #endif
}
