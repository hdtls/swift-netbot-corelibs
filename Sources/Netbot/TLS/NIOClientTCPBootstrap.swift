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

import NEAddressProcessing
import NIOCore
import NetbotLite

@available(SwiftStdlib 5.3, *)
extension NIOClientTCPBootstrap {

  /// Enable TLS.
  ///
  /// Set `isEnabled` to `false` has no effect, it define as a walkaround.
  func enableTLS(_ isEnabled: Bool) -> Self {
    guard isEnabled else {
      return self
    }
    return enableTLS()
  }

  func connect<Output>(
    to destination: Address,
    channelInitializer: @escaping @Sendable (any Channel) -> EventLoopFuture<Output>
  ) async throws -> Output where Output: Sendable {
    try await (self.underlyingBootstrap as! ClientBootstrap).connect(
      to: destination, channelInitializer: channelInitializer)
  }
}
