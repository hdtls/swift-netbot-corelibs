//
// See LICENSE.txt for license information
//

final class LwIPStackProxy: PacketHandleProtocol, Sendable {

  let packetFlow: any PacketTunnelFlow

  init(packetFlow: any PacketTunnelFlow) {
    self.packetFlow = packetFlow
  }

  func runIfActive() async throws {

  }

  func handleInput(_ packetObject: IPPacket) async throws -> PacketHandleResult {
    return .handled
  }
}
