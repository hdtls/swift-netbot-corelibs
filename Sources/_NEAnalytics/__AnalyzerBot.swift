//
// See LICENSE.txt for license information
//

import Atomics
import Logging
import NEAddressProcessing
import NIOCore

public actor __AnalyzerBot {

  private nonisolated let allocator = ByteBufferAllocator()
  private nonisolated let isActive = ManagedAtomic<Bool>(false)
  private nonisolated let packetFlow: PacketTunnelFlow
  private nonisolated let dnsServer: String
  private nonisolated let additionalDNSServers: [Address]
  private nonisolated let handles: [any PacketHandleProtocol & Sendable]
  private nonisolated var logger: Logger { AnalyzerBot.shared.logger }

  public init(
    packetFlow: PacketTunnelFlow,
    dnsServer: String,
    additionalDNSServers: [Address],
    availableIPPool: AvailableIPPool
  ) {
    self.packetFlow = packetFlow
    self.dnsServer = dnsServer
    self.additionalDNSServers = additionalDNSServers
    self.handles = [
      LocalDNSProxy(
        packetFlow: packetFlow,
        server: dnsServer,
        additionalServers: additionalDNSServers,
        availableIPPool: availableIPPool
      )
    ]
  }

  /// Start analyzer tunnel.
  nonisolated public func startVPNTunnel() async throws {
    isActive.store(true, ordering: .relaxed)

    for handle in handles {
      try await handle.runIfActive()
    }

    Task(priority: .background) {
      try await runIfActive()
    }
  }

  func runIfActive() async throws {
    guard isActive.load(ordering: .relaxed) else { return }

    for packetObject in await packetFlow.readPacketObjects() {
      for handle in handles {
        if case .handled = try await handle.handleInput(packetObject) {
          break
        }
      }
    }

    try await runIfActive()
  }

  /// Stop current running analyzer tunnel.
  nonisolated public func stopVPNTunnel() async {
    isActive.store(false, ordering: .relaxed)
  }
}
