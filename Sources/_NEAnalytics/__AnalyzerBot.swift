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
  private nonisolated let dnsServer: IPv4Address
  private nonisolated let additionalDNSServers: [Address]
  private nonisolated let handles: [any PacketHandleProtocol & Sendable]
  private nonisolated let logger: Logger = Logger(label: "AnalyzerBot")

  public init(
    group: any EventLoopGroup,
    packetFlow: PacketTunnelFlow,
    dnsServer: IPv4Address,
    additionalDNSServers: [IPv4Address],
    availableIPPool: AvailableIPPool
  ) {
    self.packetFlow = packetFlow
    self.dnsServer = dnsServer
    self.additionalDNSServers = additionalDNSServers.map { .hostPort(host: .ipv4($0), port: 53) }

    let dns = LocalDNSProxy(
      group: group,
      packetFlow: packetFlow,
      server: dnsServer,
      additionalServers: additionalDNSServers,
      availableIPPool: availableIPPool
    )

    self.handles = [
      dns,
      LwIPSOCKSProxy(packetFlow: packetFlow, dns: dns),
    ]
  }

  /// Start analyzer tunnel.
  public func run() async throws {
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

    try await runIfActive()
  }

  /// Stop current running analyzer tunnel.
  public func shutdownGracefully() async {
    isActive.store(false, ordering: .relaxed)
  }
}
