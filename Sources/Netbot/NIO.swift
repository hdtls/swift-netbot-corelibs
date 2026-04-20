// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import NIOCore
import NetbotLite

#if canImport(Network)
  import Network
  import NIOTransportServices

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  typealias DatagramClientBootstrap = NIOTSDatagramBootstrap

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension EventLoopGroup where Self == MultiThreadedEventLoopGroup {

  public static var shared: any EventLoopGroup {
    MultiThreadedEventLoopGroup.singleton
  }
}
