//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NEAddressProcessing
import NIOCore
import Testing

@testable import Networking

@Suite struct NEIPFieldsTests {

  @Test func unsupportedProtocolFamily() async throws {
    #expect(NEIPFields(storage: NEIPFields.Data([0x55])) == nil)
  }

  @Test(
    arguments: zip(
      [
        "45000034000040004006aaaac0a80764c0a80765de5ace644b2b31e3bc83ee838010005bf6a300000101080a4a8e33e1b7d3e48b"
      ], [NIOBSDSocket.AddressFamily.inet]))
  func protocolFamily(_ data: String, expected protocolFamily: NIOBSDSocket.AddressFamily)
    async throws
  {
    let data = try ByteBuffer(plainHexEncodedBytes: data)
    let headerFields = NEIPFields(storage: data)
    #expect(headerFields?.protocolFamily == protocolFamily)
  }

  @Test func data() async throws {
    let data = try ByteBuffer(
      plainHexEncodedBytes:
        "45000034000040004006aaaac0a80764c0a80765de5ace644b2b31e3bc83ee838010005bf6a300000101080a4a8e33e1b7d3e48b"
    )
    let expected = data.prefix(20)
    let headerFields = NEIPFields(storage: data)
    #expect(headerFields?.data == expected)
  }

  @Suite struct NEInFieldsTests {

    @Test func getProperties() async throws {
      let data = try ByteBuffer(
        plainHexEncodedBytes:
          "45000034000040004006aaaac0a80764c0a80765de5ace644b2b31e3bc83ee838010005bf6a300000101080a4a8e33e1b7d3e48b"
      )
      guard case .v4(let headerFields) = NEIPFields(storage: data) else {
        #expect(Bool(false))
        return
      }

      #expect(headerFields.protocolFamily == .inet)
      #expect(headerFields.internetHeaderLength == 5)
      #expect(headerFields.differentiatedServicesCodePoint == 0)
      #expect(headerFields.explicitCongestionNotification == 0)
      #expect(headerFields.totalLength == 52)
      #expect(headerFields.identification == 0)
      #expect(headerFields.flags == 2)
      #expect(headerFields.options == nil)
      #expect(headerFields.fragmentOffset == 0)
      #expect(headerFields.timeToLive == 64)
      #expect(headerFields.protocol == .tcp)
      #expect(headerFields.chksum == 0xaaaa)
      #expect(headerFields.sourceAddress.debugDescription == "192.168.7.100")
      #expect(headerFields.destinationAddress.debugDescription == "192.168.7.101")

    }

    @Test func setDSCP() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.protocolFamily == .inet)
      #expect(headerFields.internetHeaderLength == 5)
      #expect(headerFields.differentiatedServicesCodePoint == 0)
      #expect(headerFields.explicitCongestionNotification == 0)
      #expect(headerFields.totalLength == 20)

      headerFields.differentiatedServicesCodePoint = 4
      #expect(headerFields.protocolFamily == .inet)
      #expect(headerFields.internetHeaderLength == 5)
      #expect(headerFields.differentiatedServicesCodePoint == 4)
      #expect(headerFields.explicitCongestionNotification == 0)
      #expect(headerFields.totalLength == 20)
      #expect(headerFields.hasModified)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45100014000040004006AABAC0A80764C0A80765")
      #expect(headerFields.data == finalize)
    }

    @Test func setECN() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.protocolFamily == .inet)
      #expect(headerFields.internetHeaderLength == 5)
      #expect(headerFields.differentiatedServicesCodePoint == 0)
      #expect(headerFields.explicitCongestionNotification == 0)
      #expect(headerFields.totalLength == 20)

      headerFields.explicitCongestionNotification = 3
      #expect(headerFields.protocolFamily == .inet)
      #expect(headerFields.internetHeaderLength == 5)
      #expect(headerFields.differentiatedServicesCodePoint == 0)
      #expect(headerFields.explicitCongestionNotification == 3)
      #expect(headerFields.totalLength == 20)
      #expect(headerFields.hasModified)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45030014000040004006aac7c0a80764c0a80765")
      #expect(headerFields.data == finalize)
    }

    @Test func setIdentification() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.identification == 0)

      headerFields.identification = 1
      #expect(headerFields.identification == 1)
      #expect(headerFields.hasModified)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000140004006aac9c0a80764c0a80765")
      #expect(headerFields.data == finalize)
    }

    @Test func setFlags() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.flags == 2)
      #expect(headerFields.fragmentOffset == 0)

      headerFields.flags = 0
      #expect(headerFields.flags == 0)
      #expect(headerFields.fragmentOffset == 0)
      #expect(headerFields.hasModified)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000000004006eacac0a80764c0a80765")
      #expect(headerFields.data == finalize)
    }

    @Test func setFragmentOffsets() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.flags == 2)
      #expect(headerFields.fragmentOffset == 0)

      headerFields.fragmentOffset = 1
      #expect(headerFields.flags == 2)
      #expect(headerFields.fragmentOffset == 1)
      #expect(headerFields.hasModified)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000040014006aac9c0a80764c0a80765")
      #expect(headerFields.data == finalize)
    }

    @Test func setTTL() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.timeToLive == 64)

      headerFields.timeToLive = 1
      #expect(headerFields.timeToLive == 1)
      #expect(headerFields.hasModified)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000040000106e9cac0a80764c0a80765")
      #expect(headerFields.data == finalize)
    }

    @Test func setProtocol() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.protocol == .tcp)

      headerFields.protocol = .udp
      #expect(headerFields.protocol == .udp)
      #expect(headerFields.hasModified)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000014000040004011aabfc0a80764c0a80765")
      #expect(headerFields.data == finalize)
    }

    @Test func setSRCAddress() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.sourceAddress == IPv4Address("192.168.7.100")!)

      headerFields.sourceAddress = IPv4Address("1.1.1.1")!
      #expect(headerFields.sourceAddress == IPv4Address("1.1.1.1")!)
      #expect(headerFields.hasModified)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "4500001400004000400670d501010101c0a80765")
      #expect(headerFields.data == finalize)
    }

    @Test func setDSTAddress() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.destinationAddress == IPv4Address("192.168.7.101")!)

      headerFields.destinationAddress = IPv4Address("1.1.1.1")!
      #expect(headerFields.destinationAddress == IPv4Address("1.1.1.1")!)
      #expect(headerFields.hasModified)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "4500001400004000400670d6c0a8076401010101")
      #expect(headerFields.data == finalize)
    }

    @Test func setOptions() async throws {
      var data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      var headerFields = NEIPFields.NEInFields(storage: data)

      #expect(headerFields.internetHeaderLength == 5)
      #expect(headerFields.totalLength == 20)
      #expect(headerFields.options == nil)

      // Automatically fill bytes.
      headerFields.options = ByteBuffer(bytes: [0x1, 0x2, 0x3])
      #expect(headerFields.internetHeaderLength == 6)
      #expect(headerFields.totalLength == 24)
      #expect(headerFields.options == ByteBuffer(bytes: [0x1, 0x2, 0x3, 0x0]))

      // New options no payload.
      headerFields.options = ByteBuffer(bytes: [0x1, 0x6, 0x3, 0x4])
      #expect(headerFields.internetHeaderLength == 6)
      #expect(headerFields.totalLength == 24)
      #expect(headerFields.options == ByteBuffer(bytes: [0x1, 0x6, 0x3, 0x4]))
      #expect(headerFields.hasModified)

      // New options with payload.
      data = try ByteBuffer(
        plainHexEncodedBytes: "46000019000040004006aaaac0a80764c0a8076501020304a8")
      headerFields = NEIPFields.NEInFields(storage: data)
      #expect(headerFields.internetHeaderLength == 6)
      #expect(headerFields.totalLength == 25)
      #expect(headerFields.options == ByteBuffer(bytes: [0x1, 0x2, 0x3, 0x4]))

      headerFields.options = ByteBuffer(bytes: [0x1, 0x6, 0x3, 0x4])
      #expect(headerFields.internetHeaderLength == 6)
      #expect(headerFields.totalLength == 25)
      #expect(headerFields.options == ByteBuffer(bytes: [0x1, 0x6, 0x3, 0x4]))

      headerFields.options = nil
      #expect(headerFields.internetHeaderLength == 5)
      #expect(headerFields.totalLength == 21)
      #expect(headerFields.options == nil)

      let finalize = try ByteBuffer(
        plainHexEncodedBytes: "45000015000040004006aac9c0a80764c0a80765")
      #expect(headerFields.data == finalize)
    }

    @Test func customMirrorConformance() async throws {
      let data = try ByteBuffer(plainHexEncodedBytes: "45000014000040004006aaaac0a80764c0a80765")

      let fields = NEIPFields.NEInFields(storage: data)

      let mirror = Mirror(reflecting: fields)
      #expect(mirror.displayStyle == .struct)
      #expect(mirror.children.count == 15)
    }
  }
}
