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

import Logging
import NIOCore
import _DNSSupport

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension LocalDNSProxy {

  func handlePacket(_ packetObject: NEPacket) -> Bool {
    // Make it mutable, so we don't need alloc new packet for response.
    guard case .v4(let iphdr) = packetObject.headerFields else {
      // IPv4 only now.
      return false
    }

    // Large DNS query over TCP is not supported yet.
    guard iphdr.protocol == .udp else {
      return false
    }

    // Make sure the packet contains transport layer data.
    guard packetObject.payload.count >= MemoryLayout<UInt16>.size * 4 else {
      return false
    }

    // Make it mutable, so we don't need alloc another datagram for response.
    let datagram = Datagram(
      data: packetObject.payload,
      pseudoFields: .init(
        sourceAddress: iphdr.sourceAddress,
        destinationAddress: iphdr.destinationAddress,
        protocol: iphdr.protocol,
        dataLength: UInt16(packetObject.payload.count)
      )
    )

    // Confirm that the packet is send to our fake DNS server.
    guard bindAddress == iphdr.destinationAddress, datagram.destinationPort == 53 else {
      return false
    }
    return true
  }

  func handleNewPackets(_ packetObjects: some Sequence<NEPacket>) async -> [NEPacket] {
    var handled: [NEPacket] = []

    for packetObject in packetObjects {
      // Make it mutable, so we don't need alloc new packet for response.
      guard case .v4(var iphdr) = packetObject.headerFields else {
        // IPv4 only now.
        continue
      }

      // Large DNS query over TCP is not supported yet.
      guard iphdr.protocol == .udp else {
        continue
      }

      // Make sure the packet contains transport layer data.
      guard packetObject.payload.count >= MemoryLayout<UInt16>.size * 4 else {
        continue
      }

      // Make it mutable, so we don't need alloc another datagram for response.
      var datagram = Datagram(
        data: packetObject.payload,
        pseudoFields: .init(
          sourceAddress: iphdr.sourceAddress,
          destinationAddress: iphdr.destinationAddress,
          protocol: iphdr.protocol,
          dataLength: UInt16(packetObject.payload.count)
        )
      )

      // Store address to make response by exchange source/destination address and port.
      let destinationAddress = iphdr.destinationAddress
      let destinationPort = datagram.destinationPort

      // Confirm that the packet is send to our fake DNS server.
      guard bindAddress == destinationAddress, destinationPort == 53 else {
        continue
      }

      guard let dnsPayload = datagram.payload, !dnsPayload.isEmpty else {
        // If DNS message is missing, we discard this packet.
        continue
      }

      do {
        var message = try parser.parse(dnsPayload)

        var msg = "\(iphdr.sourceAddress) => \(iphdr.destinationAddress) \(iphdr.totalLength)"
        logger.info("\(msg) \(message.formatted())")
        logger.trace("\(msg) \(message.formatted(.detailed))")

        // TODO: Multiple Qestions.
        if let question = message.questions.first {
          switch question.queryType {
          case .a:
            // All communications inside of the domain protocol are carried in the same
            // message format, so we can modify query message to fake response message.
            message.headerFields.flags = .init(
              response: true,
              opcode: .query,
              authoritative: false,
              truncated: false,
              recursionDesired: false,
              recursionAvailable: false,
              authenticatedData: false,
              checkingDisabled: false,
              responseCode: .noError
            )
            message.answerRRs = try await queryDisguisedA(name: question.domainName)
            message.authorityRRs = []
            message.additionalRRs = []
            message.headerFields.answerCount = UInt16(message.answerRRs.count)
            message.headerFields.authorityCount = UInt16(message.authorityRRs.count)
            message.headerFields.additionCount = UInt16(message.additionalRRs.count)
          // TODO: IPv6 Support
          //    case .aaaa:
          default:
            message = try await query(msg: message)
          }
        } else {
          message = try await query(msg: message)
        }

        // Revese source and destination address.
        datagram.destinationPort = datagram.sourcePort
        datagram.sourcePort = destinationPort
        datagram.payload = try ByteBuffer(bytes: message.serializedBytes)
        datagram.pseudoFields.destinationAddress = datagram.pseudoFields.sourceAddress
        datagram.pseudoFields.sourceAddress = destinationAddress
        datagram.pseudoFields.dataLength = datagram.totalLength

        iphdr.differentiatedServicesCodePoint = 0
        iphdr.explicitCongestionNotification = 0
        iphdr.identification = .random(in: 0xC000 ... .max)
        iphdr.flags = 0
        iphdr.fragmentOffset = 0
        iphdr.timeToLive = 64
        iphdr.destinationAddress = iphdr.sourceAddress
        iphdr.sourceAddress = destinationAddress
        iphdr.options = nil
        iphdr.totalLength = UInt16(iphdr.data.count + datagram.data.count)

        msg = "\(iphdr.sourceAddress) => \(iphdr.destinationAddress) \(iphdr.totalLength)"
        logger.info("\(msg) \(message.formatted())")
        logger.trace("\(msg) \(message.formatted(.detailed))")

        var data = iphdr.data
        data.append(contentsOf: datagram.data)
        guard let packetObject = NEPacket(data: data, protocolFamily: iphdr.protocolFamily) else {
          continue
        }
        handled.append(packetObject)
      } catch {
        logger.error("Failed to process DNS packets \(error)")
      }
    }

    return handled
  }
}
