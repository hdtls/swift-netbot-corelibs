//
// See LICENSE.txt for license information
//

import Logging

struct LogHandle: PacketHandle {
  let logger = Logger(label: "com.tenbits.netbot.IP")

  func handle(_ packetObject: IPPacket) async throws -> PacketHandleResult {
    switch packetObject {
    case .v4(let packetObject):
      logger
        .debug(
          "\(packetObject.sourceAddress) => \(packetObject.destinationAddress) \(packetObject.protocol) \(packetObject.totalLength) \(packetObject.fragmentOffset)"
        )
      return .discarded
    case .v6(let packetObject):
      logger
        .debug(
          "\(packetObject.sourceAddress) => \(packetObject.destinationAddress)"
        )
      return .discarded
    }
  }

  func runIfActive() async throws {}
}
