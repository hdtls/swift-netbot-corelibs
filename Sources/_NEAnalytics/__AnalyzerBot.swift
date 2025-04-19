//
// See LICENSE.txt for license information
//

import Logging
import NEAddressProcessing
import NIOCore

public actor __AnalyzerBot {

  private nonisolated let allocator = ByteBufferAllocator()
  private nonisolated let packetFlow: PacketTunnelFlow
  private nonisolated let dnsServer: String
  private nonisolated let additionalDNSServers: [Address]
  private nonisolated let handles: [any PacketHandle]

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
        server: dnsServer,
        additionalServers: additionalDNSServers,
        availableIPPool: availableIPPool
      ),
      LogHandle(),
    ]
  }

  /// Start analyzer tunnel.
  nonisolated public func startVPNTunnel() async throws {
    for handle in handles {
      try await handle.runIfActive()
    }

    Task(priority: .background) {
      while true {
        try await runIfActive()
      }
    }
  }

  func runIfActive() async throws {
    var packetObjects: [IPPacket] = []

    for packetObject in await packetFlow.readPacketObjects() {
      for handle in handles {
        if case .handled(let response) = try await handle.handle(packetObject) {
          packetObjects.append(response)
          break
        }
      }
    }

    guard !packetObjects.isEmpty else { return }
    _ = packetFlow.writePacketObjects(packetObjects)
  }

  /// Stop current running analyzer tunnel.
  nonisolated public func stopVPNTunnel() async {
  }
}
