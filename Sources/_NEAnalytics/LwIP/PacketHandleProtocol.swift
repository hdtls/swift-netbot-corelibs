//
// See LICENSE.txt for license information
//

@available(SwiftStdlib 5.3, *)
enum PacketHandleResult: Hashable, Sendable {

  /// The handler processed packet.
  case handled

  /// The handler discarded packet.
  case discarded
}

@available(SwiftStdlib 5.3, *)
protocol PacketHandleProtocol {

  func runIfActive() async throws

  func handleInput(_ packetObject: NEPacket) async throws -> PacketHandleResult
}
