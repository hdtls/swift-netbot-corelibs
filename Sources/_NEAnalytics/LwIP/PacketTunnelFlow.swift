//
// See LICENSE.txt for license information
//

import NIOCore

#if canImport(NetworkExtension)
  import NetworkExtension
#endif

public protocol PacketTunnelFlow: AnyObject, Sendable {

  func readPacketObjects() async -> [NEPacket]

  func writePacketObjects(_ packets: [NEPacket]) -> Bool
}

#if canImport(NetworkExtension)
  extension NEPacketTunnelFlow: @unchecked @retroactive Sendable, PacketTunnelFlow {

    public func readPacketObjects() async -> [NEPacket] {
      let packetObjects: [NetworkExtension.NEPacket] = await readPacketObjects()
      return packetObjects.compactMap {
        switch $0.protocolFamily {
        case sa_family_t(AF_INET):
          return NEPacket(data: .init(bytes: $0.data), protocolFamily: .inet)
        case sa_family_t(AF_INET6):
          return NEPacket(data: .init(bytes: $0.data), protocolFamily: .inet)
        default:
          return nil
        }
      }
    }

    public func writePacketObjects(_ packets: [NEPacket]) -> Bool {
      let packetObjects = packets.map {
        NetworkExtension
          .NEPacket(
            data: .init(Array(buffer: $0.data)),
            protocolFamily: sa_family_t($0.protocolFamily.rawValue)
          )
      }
      return writePacketObjects(packetObjects)
    }
  }
#endif
