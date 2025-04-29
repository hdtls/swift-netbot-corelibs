//
// See LICENSE.txt for license information
//

import NELwIP
import NIOCore
import Logging

#if os(Windows)
  import ucrt

  import let WinSDK.AF_INET6

  // swift-format-ignore: TypeNamesShouldBeCapitalized
  private typealias sa_family_t = WinSDK.ADDRESS_FAMILY
#elseif canImport(Darwin)
  import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
  #if canImport(Glibc)
    import Glibc
  #elseif canImport(Musl)
    import Musl
  #elseif canImport(Android)
    import Android
  #endif
  import CNIOLinux
#elseif canImport(WASILibc)
  import WASILibc
#else
  #error("The Socket Addresses module was unable to identify your C library.")
#endif

final class LwIPStackProxy: PacketHandleProtocol, Sendable, LwIPStackDelegate {

  let packetFlow: any PacketTunnelFlow
  private let stack = LwIPStack()
  private let logger = Logger(label: "LwIP")

  init(packetFlow: any PacketTunnelFlow) {
    self.packetFlow = packetFlow
    self.stack.delegate = self
  }

  func runIfActive() async throws {
    try await stack.runIfActive()
  }

  func handleInput(_ packetObject: IPPacket) async throws -> PacketHandleResult {
    try await stack.write(packetObject.data)
    return .handled
  }

  func stack(_ stack: LwIPStack, didReceive channel: NIOAsyncChannel<ByteBuffer, ByteBuffer>) async throws {
    try await channel.executeThenClose { inbound, outbound in
      try await withThrowingTaskGroup { g in
        g.addTask {
          do {
            for try await frame in inbound {
              self.logger.trace("\(frame.hexDump(format: .detailed))")
            }
          } catch {
            self.logger.error("\(error)")
          }
        }
      }
    }
  }

  func stack(_ stack: LwIPStack, didReceive response: [ByteBuffer]) {
    let packetObjects: [IPPacket] = response.compactMap {
      guard let rawValue = $0.peekInteger(as: UInt8.self) else {
        return nil
      }
      switch rawValue >> 4 {
      case 4:
        return IPPacket(data: $0, protocolFamily: sa_family_t(AF_INET))
      case 6:
        return IPPacket(data: $0, protocolFamily: sa_family_t(AF_INET6))
      default:
        return nil
      }
    }
    guard !packetObjects.isEmpty else {
      return
    }
    packetFlow.writePacketObjects(packetObjects)
  }
}
