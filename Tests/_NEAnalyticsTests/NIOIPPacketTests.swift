//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Testing
  import Network

  #if canImport(FoundationEssentials)
    import FoundationEssentials
  #else
    import Foundation
  #endif

  @testable import _NEAnalytics

  @Suite struct NIOIPPacketTests {

    @Test func getValues() async throws {
      let data = Data([
        0x45, 0x0, 0x0, 0x34, 0x0, 0x0, 0x40, 0x0, 0x40, 0x6, 0xaa, 0xaa, 0xc0, 0xa8, 0x7, 0x64,
        0xc0,
        0xa8, 0x7, 0x65, 0xde, 0x5a, 0xce, 0x64, 0x4b, 0x2b, 0x31, 0xe3, 0xbc, 0x83, 0xee, 0x83,
        0x80,
        0x10, 0x0, 0x5b, 0xf6, 0xa3, 0x0, 0x0, 0x1, 0x1, 0x8, 0xa, 0x4a, 0x8e, 0x33, 0xe1, 0xb7,
        0xd3,
        0xe4, 0x8b,
      ])

      let packet = NIOIPPacket.IPv4Packet(data: data, protocolFamily: UInt8(AF_INET))
      #expect(packet.protocolFamily == UInt8(AF_INET))
      #expect(packet.internetHeaderLength == 5)
      #expect(packet.differentiatedServicesCodePoint == 0)
      #expect(packet.explicitCongestionNotification == 0)
      #expect(packet.totalLength == 52)
      #expect(packet.identification == 0)
      #expect(packet.flags == 2)
      #expect(packet.options == nil)
      #expect(packet.fragmentOffset == 0)
      #expect(packet.timeToLive == 64)
      #expect(packet.protocol == .tcp)
      #expect(packet.headerChecksum == 0xaaaa)
      #expect(packet.sourceAddress.debugDescription == "192.168.7.100")
      #expect(packet.destinationAddress.debugDescription == "192.168.7.101")
      #expect(packet.payload.count == 32)
    }

    @Test func setValues() async throws {
      let data = Data([
        0x45, 0x0, 0x0, 0x34, 0x0, 0x0, 0x40, 0x0, 0x40, 0x6, 0xaa, 0xaa, 0xc0, 0xa8, 0x7, 0x64,
        0xc0,
        0xa8, 0x7, 0x65, 0xde, 0x5a, 0xce, 0x64, 0x4b, 0x2b, 0x31, 0xe3, 0xbc, 0x83, 0xee, 0x83,
        0x80,
        0x10, 0x0, 0x5b, 0xf6, 0xa3, 0x0, 0x0, 0x1, 0x1, 0x8, 0xa, 0x4a, 0x8e, 0x33, 0xe1, 0xb7,
        0xd3,
        0xe4, 0x8b,
      ])

      var packet = NIOIPPacket.IPv4Packet(data: data, protocolFamily: UInt8(AF_INET))
      #expect(packet.protocolFamily == UInt8(AF_INET))

      packet.internetHeaderLength = 5
      #expect(packet.internetHeaderLength == 5)

      packet.differentiatedServicesCodePoint = 0
      #expect(packet.differentiatedServicesCodePoint == 0)

      packet.explicitCongestionNotification = 0
      #expect(packet.explicitCongestionNotification == 0)

      packet.totalLength = 52
      #expect(packet.totalLength == 52)

      packet.identification = 0
      #expect(packet.identification == 0)

      packet.flags = 2
      #expect(packet.flags == 2)

      packet.options = nil
      #expect(packet.options == nil)

      packet.fragmentOffset = 0
      #expect(packet.fragmentOffset == 0)

      packet.timeToLive = 64
      #expect(packet.timeToLive == 64)

      packet.protocol = .tcp
      #expect(packet.protocol == .tcp)

      #expect(packet.headerChecksum == 0xaaaa)

      packet.sourceAddress = IPv4Address("192.168.7.100")!
      #expect(packet.sourceAddress.debugDescription == "192.168.7.100")

      packet.destinationAddress = IPv4Address("192.168.7.101")!
      #expect(packet.destinationAddress.debugDescription == "192.168.7.101")

      packet.payload.count = 32
      #expect(packet.payload.count == 32)

      #expect(packet.data == data)
    }

    @Test(arguments: [
      [
        0x45, 0x0, 0x0, 0x48, 0x84, 0x98, 0x0, 0x0, 0x40, 0x11, 0x69, 0xe5, 0xc6, 0x12, 0x0, 0x1,
        0xc6, 0x12, 0x0, 0x2,
      ],
      [
        0x45, 0x0, 0x0, 0x28, 0x86, 0x2, 0x0, 0x0, 0x40, 0x6, 0xa2, 0x71, 0xc0, 0xa8, 0x7, 0x65,
        0xc6,
        0x29, 0xc4, 0x25,
      ],
      [
        0x45, 0x0, 0x0, 0x73, 0x7b, 0x3f, 0x0, 0x0, 0xff, 0x11, 0x97, 0x31, 0xc0, 0xa8, 0x7, 0x65,
        0xe0, 0x0, 0x0, 0xfb,
      ],
      [
        0x45, 0x0, 0x0, 0x4c, 0x0, 0x0, 0x40, 0x0, 0x40, 0x6, 0xd6, 0xf1, 0xc0, 0xa8, 0x7, 0x65,
        0x68,
        0x12, 0x33, 0x9b,
      ],
    ])
    func chksum(bytes: [UInt8]) {
      let data = Data(bytes)
      let packet = NIOIPPacket(data: data, protocolFamily: sa_family_t(AF_INET))
      #expect(packet.chksum(data, length: data.count) == 0)
    }
  }
#endif
