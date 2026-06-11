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

#if canImport(NetworkExtension)
  import NetbotXPC
  import NetworkExtension

  @available(SwiftStdlib 6.0, *)
  public typealias NEProxySettings = NetbotXPC.NEProxySettings

  // swift-format-ignore: AvoidRetroactiveConformances
  @available(SwiftStdlib 6.0, *)
  extension NEIPv4Settings: @retroactive @unchecked Sendable {}

  // swift-format-ignore: AvoidRetroactiveConformances
  @available(SwiftStdlib 6.0, *)
  extension NEDNSSettings: @retroactive @unchecked Sendable {}
#else
  @available(SwiftStdlib 6.0, *)
  public struct NEDNSSettings: Hashable, Sendable {
    public var servers: [String]

    public var matchDomains: [String]?

    public init(servers: [String]) {
      self.servers = servers
    }
  }

  @available(SwiftStdlib 6.0, *)
  public struct NEProxyServer: Hashable, Sendable {
    public var address: String
    public var port: Int

    public init(address: String, port: Int) {
      self.address = address
      self.port = port
    }
  }

  @available(SwiftStdlib 6.0, *)
  public struct NEProxySettings: Hashable, Sendable {

    public var httpEnabled = false
    public var httpServer: NEProxyServer?
    public var httpsEnabled = false
    public var httpsServer: NEProxyServer?
    public var socksEnabled = false
    public var socksServer: NEProxyServer?
    public var excludeSimpleHostnames = false
    public var exceptionList: [String] = []

    public init() {}
  }

  @available(SwiftStdlib 6.0, *)
  public struct NEIPv4Route: Hashable, Sendable {

    public let destinationAddress: String

    public let subnetMask: String

    public init(destinationAddress: String, subnetMask: String) {
      self.destinationAddress = destinationAddress
      self.subnetMask = subnetMask
    }

    public static func `default`() -> NEIPv4Route {
      NEIPv4Route(destinationAddress: "", subnetMask: "")
    }
  }

  @available(SwiftStdlib 6.0, *)
  public struct NEIPv4Settings: Hashable, Sendable {

    public let addresses: [String]

    public let subnetMasks: [String]

    public var includedRoutes: [NEIPv4Route] = []

    public var excludedRoutes: [NEIPv4Route] = []

    public init(addresses: [String], subnetMasks: [String]) {
      self.addresses = addresses
      self.subnetMasks = subnetMasks
    }
  }
#endif

@available(SwiftStdlib 6.0, *)
public struct NEPacketTunnelNetworkSettings: Hashable, Sendable {

  public let tunnelRemoteAddress: String

  public var dnsSettings: NEDNSSettings?

  public var proxySettings: NEProxySettings?

  public var ipv4Settings: NEIPv4Settings?

  public init(tunnelRemoteAddress: String) {
    self.tunnelRemoteAddress = tunnelRemoteAddress
  }
}
