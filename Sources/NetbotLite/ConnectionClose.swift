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
import NetbotLiteData
import Synchronization

@available(SwiftStdlib 6.0, *)
class ConnectionClose: ChannelInboundHandler {
  typealias InboundIn = Never

  private let connection: Connection

  init(connection: Connection) {
    self.connection = connection
  }

  func channelInactive(context: ChannelHandlerContext) {
    connection.$state.withLock {
      if !$0.isFinished {
        $0 = .completed
      }
    }
    context.fireChannelInactive()
  }
}
