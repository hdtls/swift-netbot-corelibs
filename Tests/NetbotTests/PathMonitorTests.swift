// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import NEAddressProcessing
import NIOCore
import Testing

@testable import Netbot

#if canImport(Network)
  import Network
#endif

@Suite struct PathMonitorTests {

  @Suite struct PathTests {

    @available(SwiftStdlib 6.0, *)
    @Test func statusCases() async throws {
      let satisfied: Path.Status = .satisfied
      let unsatisfied: Path.Status = .unsatisfied
      let requires: Path.Status = .requiresConnection
      #expect(satisfied != unsatisfied)
      #expect(requires != satisfied)
      #expect(Set([satisfied, unsatisfied, requires, requires]).count == 3)
    }

    @available(SwiftStdlib 6.0, *)
    @Test func unsatisfiedReasonCases() async throws {
      let reasons: [Path.UnsatisfiedReason] = [
        .notAvailable, .notAvailable, .cellularDenied, .wifiDenied, .localNetworkDenied,
        .vpnInactive,
      ]
      #expect(Set(reasons).count == 5)
      #expect(Path.UnsatisfiedReason.notAvailable == .notAvailable)
      #expect(Path.UnsatisfiedReason.cellularDenied != .vpnInactive)
    }

    @available(anyAppleOS 26.0, *)
    @Test func linkQualityCases() async throws {
      let values: [Path.LinkQuality] = [.unknown, .minimal, .moderate, .good]
      #expect(Set(values).count == 4)
      #expect(Path.LinkQuality.unknown == .unknown)
      #expect(Path.LinkQuality.good != .minimal)
    }

    #if !canImport(Network)
      @Test func interfaceProperties() async throws {
        let device = try NIONetworkDevice(
          name: "en0", address: SocketAddress(ipAddress: "192.168.0.105", port: 0),
          netmask: SocketAddress(ipAddress: "255.255.255.0", port: 0),
          broadcastAddress: SocketAddress(ipAddress: "192.168.0.255", port: 0),
          pointToPointDestinationAddress: SocketAddress(ipAddress: "192.168.0.255", port: 0),
          multicastSupported: true, interfaceIndex: 9)
        let iface = Path.Interface(backing: device)
        #expect(iface.name == "en0")
        #expect(iface.index == 9)
        #expect(!iface.addresses.isEmpty)

        let copy = iface
        #expect(copy == iface)
        #expect(Set([iface, copy]).count == 1)
      }
    #endif

    @available(anyAppleOS 26.0, *)
    @Test func pathProperties() async throws {
      #if canImport(Network)
        let availableInterfaces: [Path.Interface] = []
      #else
        let device = try NIONetworkDevice(
          name: "en0", address: SocketAddress(ipAddress: "192.168.0.105", port: 0),
          netmask: SocketAddress(ipAddress: "255.255.255.0", port: 0),
          broadcastAddress: SocketAddress(ipAddress: "192.168.0.255", port: 0),
          pointToPointDestinationAddress: SocketAddress(ipAddress: "192.168.0.255", port: 0),
          multicastSupported: true, interfaceIndex: 9)
        let iface = Path.Interface(backing: device)
        let availableInterfaces: [Path.Interface] = [iface]
      #endif
      let path = Path(
        status: .satisfied, availableInterfaces: availableInterfaces, isExpensive: true,
        isConstrained: true, isUltraConstrained: true, supportsIPv4: true, supportsIPv6: true,
        supportsDNS: true, gateways: [.hostPort(host: "192.168.0.1", port: 0)],
        localEndpoint: .hostPort(host: "192.168.0.32", port: 23124),
        remoteEndpoint: .hostPort(host: "172.32.2.1", port: 80), linkQuality: .good)

      #expect(path.status == .satisfied)
      #expect(path.availableInterfaces == availableInterfaces)
      #expect(path.isExpensive)
      #expect(path.isConstrained)
      #expect(path.isUltraConstrained)
      #expect(path.supportsIPv4)
      #expect(path.supportsIPv6)
      #expect(path.supportsDNS)
      #expect(path.gateways == [.hostPort(host: "192.168.0.1", port: 0)])
      #expect(path.localEndpoint == .hostPort(host: "192.168.0.32", port: 23124))
      #expect(path.remoteEndpoint == .hostPort(host: "172.32.2.1", port: 80))
      #expect(path.linkQuality == .good)

      let copy = path
      #expect(copy == path)
    }
  }
}
