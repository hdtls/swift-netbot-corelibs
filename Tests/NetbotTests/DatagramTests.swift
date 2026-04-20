// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import NEAddressProcessing
import NIOCore
import Testing

@testable import Netbot

@Suite struct DatagramTests {

  let data = try! ByteBuffer(
    plainHexEncodedBytes:
      "f0960035002e24b4cca801200001000000000001057377696674036f726700000100010000291000000000000000"
  )

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  var datagram: Datagram {
    Datagram(
      data: data,
      pseudoFields: .init(
        sourceAddress: .init("192.168.7.102")!,
        destinationAddress: .init("116.116.116.116")!,
        protocol: .udp,
        dataLength: 46
      )
    )
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func getValues() async throws {
    #expect(datagram.sourcePort == 61590)
    #expect(datagram.destinationPort == 53)
    #expect(datagram.totalLength == 46)
    #expect(datagram.chksum == 0x24b4)
    #expect(throws: Never.self) {
      let payload = try ByteBuffer(
        plainHexEncodedBytes:
          "cca801200001000000000001057377696674036f726700000100010000291000000000000000")
      #expect(datagram.payload == payload)
    }
    #expect(datagram.pseudoFields.sourceAddress == IPv4Address("192.168.7.102")!)
    #expect(datagram.pseudoFields.destinationAddress == IPv4Address("116.116.116.116")!)
    #expect(datagram.pseudoFields.protocol == .udp)
    #expect(datagram.pseudoFields.dataLength == 46)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func setSRCPort() async throws {
    var datagram = self.datagram
    datagram.sourcePort = 12345
    #expect(datagram.sourcePort == 12345)
    datagram.sourcePort = 61590
    #expect(datagram.sourcePort == 61590)
    #expect(datagram.data == data)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func setDSTPort() async throws {
    var datagram = self.datagram
    datagram.destinationPort = 12345
    #expect(datagram.destinationPort == 12345)
    datagram.destinationPort = 53
    #expect(datagram.destinationPort == 53)
    #expect(datagram.data == data)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func setPayload() async throws {
    var datagram = self.datagram
    let payload = datagram.payload
    #expect(datagram.data == data)
    datagram.payload = nil
    #expect(datagram.payload == ByteBuffer())
    #expect(datagram.totalLength == 8)
    datagram.payload = payload
    #expect(datagram.payload == payload)
    #expect(datagram.totalLength == 46)
    #expect(datagram.pseudoFields.dataLength == 46)
    #expect(datagram.data == data)
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func setPseudoFields() async throws {
    var datagram = self.datagram
    let pseudoFields = PseudoFields(
      sourceAddress: IPv4Address("1.1.1.1")!,
      destinationAddress: IPv4Address("2.2.2.2")!,
      protocol: .udp,
      dataLength: 46
    )
    datagram.pseudoFields = pseudoFields
    #expect(datagram.pseudoFields == pseudoFields)
    datagram.pseudoFields = self.datagram.pseudoFields
    #expect(datagram.pseudoFields == self.datagram.pseudoFields)
    #expect(datagram.data == data)
  }
}
