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

import NIOCore

#if canImport(NetworkExtension)
  import NetworkExtension
#endif

@available(SwiftStdlib 5.3, *)
public protocol PacketTunnelFlow: AnyObject, Sendable {

  func readPacketObjects() async -> [NEPacket]

  func writePacketObjects(_ packets: [NEPacket]) -> Bool
}

#if canImport(NetworkExtension)
  // swift-format-ignore: AvoidRetroactiveConformances
  @available(SwiftStdlib 5.3, *)
  extension NEPacketTunnelFlow: @retroactive @unchecked Sendable, PacketTunnelFlow {

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
