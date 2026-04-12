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

import Atomics
import Logging
import NEAddressProcessing
import NIOCore

@available(SwiftStdlib 5.3, *)
public actor AnalyzeIPBot {

  private nonisolated let isActive = ManagedAtomic<Bool>(false)
  private nonisolated let packetFlow: PacketTunnelFlow
  private nonisolated let handles: [any PacketHandleProtocol & Sendable]
  private nonisolated let logger: Logger = Logger(label: "AnalyzeIPBot")

  public init(
    group: any EventLoopGroup,
    packetFlow: PacketTunnelFlow,
    dns: LocalDNSProxy
  ) {
    self.packetFlow = packetFlow
    self.handles = [
      dns,
      LwIPSOCKSProxy(group: group, packetFlow: packetFlow, dns: dns),
    ]
  }

  /// Start analyze tunnel.
  public func run() async throws {
    isActive.store(true, ordering: .relaxed)

    for handle in handles {
      try await handle.run()
    }

    Task(priority: .background) {
      try await readPacketsIfActive()
    }
  }

  private func readPacketsIfActive() async throws {
    guard isActive.load(ordering: .relaxed) else { return }

    for packetObject in await packetFlow.readPacketObjects() {
      for handle in handles {
        do {
          if case .handled = try await handle.handleInput(packetObject) {
            break
          }
        } catch {
          // Drop packet.
          logger.error("Packet object \(packetObject) input failure with error: \(error)")
          continue
        }
      }
    }

    try await readPacketsIfActive()
  }

  /// Stop current running analyze tunnel.
  public func shutdownGracefully() async {
    isActive.store(false, ordering: .relaxed)
  }
}
