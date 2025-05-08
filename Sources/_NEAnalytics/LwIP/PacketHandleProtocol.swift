//
// See LICENSE.txt for license information
//

enum PacketHandleResult: Hashable, Sendable {

  /// The handler processed packet.
  case handled

  /// The handler discarded packet.
  case discarded
}

protocol PacketHandleProtocol {

  var packetFlow: any PacketTunnelFlow { get }

  func runIfActive() async throws

  func handleInput(_ packetObject: NEPacket) async throws -> PacketHandleResult
}
