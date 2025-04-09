//
// See LICENSE.txt for license information
//

#if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  enum PacketHandleResult: Hashable, Sendable {

    /// The handler processed packet.
    case handled(IPPacket)

    /// The handler discarded packet.
    case discarded
  }

  protocol PacketHandle: Sendable {

    func handle(_ packetObject: IPPacket) async throws -> PacketHandleResult

    func runIfActive() async throws
  }
#endif
