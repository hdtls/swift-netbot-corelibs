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

import NIOCore

#if canImport(Network)
  import Network
  import NIOTransportServices

  @available(SwiftStdlib 5.3, *)
  public typealias MultiThreadedEventLoopGroup = NIOTSEventLoopGroup
  @available(SwiftStdlib 5.3, *)
  typealias DatagramClientBootstrap = NIOTSDatagramBootstrap

  @available(SwiftStdlib 5.3, *)
  extension DatagramClientBootstrap {

    func connect<Output>(
      to address: SocketAddress,
      channelInitializer: @escaping @Sendable (any Channel) -> EventLoopFuture<Output>
    ) async throws -> Output where Output: Sendable {
      try await connect(to: address).flatMap(channelInitializer).get()
    }
  }
#else
  import NIOPosix

  public typealias MultiThreadedEventLoopGroup = NIOPosix.MultiThreadedEventLoopGroup
  typealias DatagramClientBootstrap = DatagramBootstrap
#endif

@available(SwiftStdlib 5.3, *)
extension EventLoopGroup where Self == MultiThreadedEventLoopGroup {

  public static var shared: any EventLoopGroup {
    MultiThreadedEventLoopGroup.singleton
  }
}
