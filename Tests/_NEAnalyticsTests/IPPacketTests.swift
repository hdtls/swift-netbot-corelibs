//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Testing
  import NEAddressProcessing
  import NIOCore

  @testable import _NEAnalytics

  @Suite struct IPPacketTests {

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

    @Test func ipv4CustomMirrorConformance() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      let packet = IPPacket.IPv4Packet(data: data)

      let mirror = Mirror(reflecting: packet)
      #expect(mirror.displayStyle == .struct)
      #expect(mirror.children.count == 16)
    }

    @Test func setIPv4DSCP() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.protocolFamily == 4)
      #expect(packet.internetHeaderLength == 5)
      #expect(packet.differentiatedServicesCodePoint == 0)
      #expect(packet.explicitCongestionNotification == 0)
      #expect(packet.totalLength == 20)

      packet.differentiatedServicesCodePoint = 4
      #expect(packet.protocolFamily == 4)
      #expect(packet.internetHeaderLength == 5)
      #expect(packet.differentiatedServicesCodePoint == 4)
      #expect(packet.explicitCongestionNotification == 0)
      #expect(packet.totalLength == 20)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45100014000040004006AABAC0A80764C0A80765")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4ECN() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.protocolFamily == 4)
      #expect(packet.internetHeaderLength == 5)
      #expect(packet.differentiatedServicesCodePoint == 0)
      #expect(packet.explicitCongestionNotification == 0)
      #expect(packet.totalLength == 20)

      packet.explicitCongestionNotification = 3
      #expect(packet.protocolFamily == 4)
      #expect(packet.internetHeaderLength == 5)
      #expect(packet.differentiatedServicesCodePoint == 0)
      #expect(packet.explicitCongestionNotification == 3)
      #expect(packet.totalLength == 20)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45030014000040004006aac7c0a80764c0a80765")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4Identification() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.identification == 0)

      packet.identification = 1
      #expect(packet.identification == 1)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000140004006aac9c0a80764c0a80765")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4Flags() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.flags == 2)
      #expect(packet.fragmentOffset == 0)

      packet.flags = 0
      #expect(packet.flags == 0)
      #expect(packet.fragmentOffset == 0)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000000004006eacac0a80764c0a80765")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4FragmentOffsets() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.flags == 2)
      #expect(packet.fragmentOffset == 0)

      packet.fragmentOffset = 1
      #expect(packet.flags == 2)
      #expect(packet.fragmentOffset == 1)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000040014006aac9c0a80764c0a80765")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4TTL() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.timeToLive == 64)

      packet.timeToLive = 1
      #expect(packet.timeToLive == 1)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000040000106e9cac0a80764c0a80765")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4Protocol() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.protocol == .tcp)

      packet.protocol = .udp
      #expect(packet.protocol == .udp)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000040004011aabfc0a80764c0a80765")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4SRCAddress() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.sourceAddress == IPv4Address("192.168.7.100")!)

      packet.sourceAddress = IPv4Address("1.1.1.1")!
      #expect(packet.sourceAddress == IPv4Address("1.1.1.1")!)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "4500001400004000400670d501010101c0a80765")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4DSTAddress() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.destinationAddress == IPv4Address("192.168.7.101")!)

      packet.destinationAddress = IPv4Address("1.1.1.1")!
      #expect(packet.destinationAddress == IPv4Address("1.1.1.1")!)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "4500001400004000400670d6c0a8076401010101")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4Options() async throws {
      var data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.internetHeaderLength == 5)
      #expect(packet.totalLength == 20)
      #expect(packet.options == nil)
      #expect(packet.payload == nil)

      // Automatically fill bytes.
      packet.options = ByteBuffer(bytes: [0x1, 0x2, 0x3])
      #expect(packet.internetHeaderLength == 6)
      #expect(packet.totalLength == 24)
      #expect(packet.options == ByteBuffer(bytes: [0x1, 0x2, 0x3, 0x0]))
      #expect(packet.payload == nil)

      // New options no payload.
      packet.options = ByteBuffer(bytes: [0x1, 0x6, 0x3, 0x4])
      #expect(packet.internetHeaderLength == 6)
      #expect(packet.totalLength == 24)
      #expect(packet.options == ByteBuffer(bytes: [0x1, 0x6, 0x3, 0x4]))
      #expect(packet.payload == nil)

      // New options with payload.
      data = try ByteBuffer(
        plainHexEncodedBytes: "46000019000040004006aaaac0a80764c0a8076501020304a8")
      packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.internetHeaderLength == 6)
      #expect(packet.totalLength == 25)
      #expect(packet.options == ByteBuffer(bytes: [0x1, 0x2, 0x3, 0x4]))
      #expect(packet.payload == ByteBuffer(bytes: [0xa8]))

      packet.options = ByteBuffer(bytes: [0x1, 0x6, 0x3, 0x4])
      #expect(packet.internetHeaderLength == 6)
      #expect(packet.totalLength == 25)
      #expect(packet.options == ByteBuffer(bytes: [0x1, 0x6, 0x3, 0x4]))
      #expect(packet.payload == ByteBuffer(bytes: [0xa8]))

      packet.options = nil
      #expect(packet.internetHeaderLength == 5)
      #expect(packet.totalLength == 21)
      #expect(packet.options == nil)
      #expect(packet.payload == ByteBuffer(bytes: [0xa8]))

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000015000040004006aac9c0a80764c0a80765a8")
      #expect(packet.data == finalize)
    }

    @Test func setIPv4Payload() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var packet = IPPacket.IPv4Packet(data: data)
      #expect(packet.payload == nil)

      packet.payload = ByteBuffer(bytes: [0x1])
      #expect(packet.payload == ByteBuffer(bytes: [0x1]))

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000015000040004006aac9c0a80764c0a8076501")
      #expect(packet.data == finalize)
    }
  }
#endif
