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

  private var logger: Logger { AnalyzerBot.shared.logger }

  public init(packetFlow: PacketTunnelFlow, dnsServer: String, additionalDNSServers: [Address]) {
    self.packetFlow = packetFlow
    self.dnsServer = dnsServer
    self.additionalDNSServers = additionalDNSServers
    self.handles = [
      LocalDNSProxy(
        server: dnsServer,
        additionalServers: additionalDNSServers
      )
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
        guard case .handled(let response) = try await handle.handle(packetObject) else {
          continue
        }
        packetObjects.append(response)
      }
    }

    _ = packetFlow.writePacketObjects(packetObjects)
  }

  /// Stop current running analyzer tunnel.
  nonisolated public func stopVPNTunnel() async {
  }
}
