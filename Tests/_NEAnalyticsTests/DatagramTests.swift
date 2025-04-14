//
// See LICENSE.txt for license information
//

import NEAddressProcessing
import NIOCore
import Testing

@testable import _NEAnalytics

@Suite struct DatagramTests {

  @Test func ensureHasAtLeast20Bytes() async throws {
    let data = IPPacket(data: ByteBuffer(bytes: [0x45, 0x0]), protocolFamily: 4)
    #expect(data.data.readableBytes == 20)
  }

  @Test func getValues() async throws {
    let data = try ByteBuffer(
      plainHexEncodedBytes:
        "45000034000040004006aaaac0a80764c0a80765de5ace644b2b31e3bc83ee838010005bf6a300000101080a4a8e33e1b7d3e48b"
    )

    let p = IPPacket(data: data, protocolFamily: 4)
    #expect(p.protocolFamily == 4)

    let packet = IPPacket.IPv4Packet(data: data)
    #expect(p.data == packet.data)

    #expect(packet.protocolFamily == 4)
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
    #expect(packet.chksum == 0xaaaa)
    #expect(packet.sourceAddress.debugDescription == "192.168.7.100")
    #expect(packet.destinationAddress.debugDescription == "192.168.7.101")
    #expect(packet.payload?.readableBytes == 32)
  }

  @Test func setSRCPort() async throws {
    let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

    var packet = IPPacket.IPv4Packet(data: data)
    #expect(packet.sourceAddress == IPv4Address("192.168.7.100")!)

    packet.sourceAddress = IPv4Address("1.1.1.1")!
    #expect(packet.sourceAddress == IPv4Address("1.1.1.1")!)

    let finalize = try ByteBuffer(
      plainHexEncodedBytes: "4500001400004000400670d501010101c0a80765")
    #expect(packet.data == finalize)
  }

  @Test func setDSTPort() async throws {
    let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

    var packet = IPPacket.IPv4Packet(data: data)
    #expect(packet.destinationAddress == IPv4Address("192.168.7.101")!)

    packet.destinationAddress = IPv4Address("1.1.1.1")!
    #expect(packet.destinationAddress == IPv4Address("1.1.1.1")!)

    let finalize = try ByteBuffer(
      plainHexEncodedBytes: "4500001400004000400670d6c0a8076401010101")
    #expect(packet.data == finalize)
  }

  @Test func setTotalLength() async throws {

  }

  @Test func setPayload() async throws {
    let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

    var packet = IPPacket.IPv4Packet(data: data)
    #expect(packet.payload == nil)

    packet.payload = ByteBuffer(bytes: [0x1])
    #expect(packet.payload == ByteBuffer(bytes: [0x1]))

    let finalize = try ByteBuffer(
      plainHexEncodedBytes: "45000015000040004006aac9c0a80764c0a8076501")
    #expect(packet.data == finalize)
  }

  @Test func setPseudoFields() async throws {

  }
}
