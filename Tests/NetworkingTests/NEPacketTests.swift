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

@Suite struct NEPacketTests {

  @Test func getValues() async throws {
    let data = try ByteBuffer(
      plainHexEncodedBytes:
        "45000034000040004006aaaac0a80764c0a80765de5ace644b2b31e3bc83ee838010005bf6a300000101080a4a8e33e1b7d3e48b"
    )
    guard let packet = NEPacket(data: data, protocolFamily: .inet) else {
      #expect(Bool(false))
      return
    }
    guard case .v4(let headerFields) = packet.headerFields else {
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
    #expect(packet.protocolFamily == .inet)
    #expect(packet.payload.readableBytes == 32)
  }

  @Test func unsupportedAddressFamily() async throws {
    #expect(NEPacket(data: .init(bytes: [0x55]), protocolFamily: .inet) == nil)
  }
}
