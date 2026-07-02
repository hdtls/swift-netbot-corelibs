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

import NEAddressProcessing
import NIOCore

#if canImport(Network)
  @_exported import NIOTransportServices

  @available(SwiftStdlib 6.0, *)
  public typealias ClientBootstrap = NIOTransportServices.NIOTSConnectionBootstrap

  @available(SwiftStdlib 6.0, *)
  public typealias ServerBootstrap = NIOTransportServices.NIOTSListenerBootstrap

  @available(SwiftStdlib 6.0, *)
  public typealias MultiThreadedEventLoopGroup = NIOTransportServices.NIOTSEventLoopGroup

  @available(SwiftStdlib 6.0, *)
  extension MultiThreadedEventLoopGroup {

    public convenience init(numberOfThreads: Int) {
      self.init(loopCount: numberOfThreads)
    }
  }
#else
  @_exported import NIOPosix

  public typealias ClientBootstrap = NIOPosix.ClientBootstrap

  public typealias ServerBootstrap = NIOPosix.ServerBootstrap

  public typealias MultiThreadedEventLoopGroup = NIOPosix.MultiThreadedEventLoopGroup
#endif
