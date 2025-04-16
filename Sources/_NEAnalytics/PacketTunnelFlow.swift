//
// See LICENSE.txt for license information
//

import NIOCore

#if canImport(NetworkExtension)
  import NetworkExtension
#endif

public protocol PacketTunnelFlow: Sendable {

  func readPacketObjects() async -> [IPPacket]

  func writePacketObjects(_ packets: [IPPacket]) -> Bool
}

#if canImport(NetworkExtension)
  extension NEPacketTunnelFlow: @unchecked @retroactive Sendable, PacketTunnelFlow {

    public func readPacketObjects() async -> [IPPacket] {
      let packetObjects: [NEPacket] = await readPacketObjects()
      return packetObjects.filter { $0.protocolFamily == sa_family_t(AF_INET) }.map {
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
