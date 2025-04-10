//
// See LICENSE.txt for license information
//

#if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  #if canImport(Darwin)
    import NetworkExtension
  #endif

  public protocol PacketTunnelFlow: Sendable {

    func readPacketObjects() async -> [IPPacket]

    func writePacketObjects(_ packets: [IPPacket]) -> Bool
  }

  #if canImport(Darwin)
    extension NEPacketTunnelFlow: @unchecked @retroactive Sendable, PacketTunnelFlow {

      public func readPacketObjects() async -> [IPPacket] {
        let packetObjects: [NEPacket] = await readPacketObjects()
        return packetObjects.map {
          IPPacket(data: .init(bytes: $0.data), protocolFamily: $0.protocolFamily)
        }
      }

      public func writePacketObjects(_ packets: [IPPacket]) -> Bool {
        let packetObjects = packets.map {
          NEPacket(data: .init(Array(buffer: $0.data)), protocolFamily: $0.protocolFamily)
        }
        return writePacketObjects(packetObjects)
      }
    }
  #endif
#endif
