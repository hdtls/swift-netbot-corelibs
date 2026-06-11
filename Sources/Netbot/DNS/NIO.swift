// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import NIOCore
import NetbotLite

#if canImport(Network)
  import Network
  import NIOTransportServices

  @available(SwiftStdlib 6.0, *)
  typealias DatagramClientBootstrap = NIOTSDatagramBootstrap

  @available(SwiftStdlib 6.0, *)
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

  typealias DatagramClientBootstrap = DatagramBootstrap
#endif

@available(SwiftStdlib 6.0, *)
extension EventLoopGroup where Self == MultiThreadedEventLoopGroup {

  public static var shared: any EventLoopGroup {
    MultiThreadedEventLoopGroup.singleton
  }
}
