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

import Logging
import NEAddressProcessing
import NIOCore
import NIOSSL
import NetbotDNS
import NetbotLite
import NetbotProfile

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import class Foundation.UserDefaults
#else
  import Foundation
#endif

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  import SynchronizationExtras
#else
  import Synchronization
#endif

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

#if canImport(NetworkExtension)
  import NetbotXPC
  import NetworkExtension
#endif

/// Assistant to manage PacketTunnelProvider and NIO proxy servers backend.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public actor AnalyzeBot {

  nonisolated private let dns: LocalDNSProxy
  nonisolated private let core: NetbotLite.AnalyzeBot

  #if NETBOT_REQUIRES_LWIP
    private var coreLwIP: LwIP?
  #endif

  nonisolated public let group: any EventLoopGroup
  public var logger: Logger = Logger(label: "AnalyzeBot")

  private var proxySettings: NEProxySettings?

  public init(group: any EventLoopGroup = .shared) {
    self.group = group
    self.dns = .init(group: group)
    self.core = .init(group: group, logger: logger)
  }

  /// Start analyze tunnel.
  public func run() async throws {
    #if os(macOS)
      let toolVersion = try await PHT.toolVersion()
      logger.trace("PHT version: \(toolVersion)")

      await self.core.setProcessInfo(ProcessResolver.shared)
    #endif

    let publisher = ConnectionPulse(group: group, address: .hostPort(host: "127.0.0.1", port: 6170))
    await self.core.setConnectionPublisher(publisher)
    await self.core.setResolver(dns)
    try await publisher.run()
    try await self.core.run()
  }

  /// Stop current running analyze tunnel.
  public func shutdownGracefully() async {
    let publisher = self.core.connectionPublisher as? ConnectionPulse
    try? await publisher?.shutdownGracefully()
    try? await self.core.shutdownGracefully()
  }

  public func setLogger(_ logger: Logger) async {
    self.logger = logger
  }

  /// Modify outbound mode.
  public func setOutboundMode(_ outboundMode: OutboundMode) async {
    guard outboundMode != core.outboundMode else { return }

    await self.core.setOutboundMode(outboundMode)
    logger.info("Outbound mode has been changed to \(outboundMode.localizedName)")
  }

  /// Modify global forward protocol.
  public func setForwardProtocol(_ forwardProtocol: any ForwardProtocolConvertible) async {
    await core.setForwardProtocol(forwardProtocol)
  }

  /// Modify forwarding rules.
  public func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) async {
    await core.setForwardingRules(forwardingRules)
  }

  /// Modify enabled HTTP capabilities.
  public func setEnabledHTTPCapabilities(_ enabledHTTPCapabilities: CapabilityFlags) async {
    await self.core.setEnabledHTTPCapabilities(enabledHTTPCapabilities)
  }

  /// Modify HTTPS decryption PKCS#12 bundle.
  public func setDecryptionSSLPKCS12Bundle(_ sslPKCS12Bundle: NIOSSLPKCS12Bundle?) async {
    await self.core.setDecryptionSSLPKCS12Bundle(sslPKCS12Bundle)
  }

  /// Modify settings using specific profile.
  public func setTunnelNetworkSettings(_ tunnelNetworkSettings: NEPacketTunnelNetworkSettings?)
    async throws
  {
    let proxySettings = tunnelNetworkSettings?.proxySettings

    try await core.setTunnelNetworkSettings(
      (
        SocketAddress(
          ipAddress: proxySettings?.httpsServer?.address ?? "127.0.0.1",
          port: proxySettings?.httpsServer?.port ?? 6152),
        SocketAddress(
          ipAddress: proxySettings?.socksServer?.address ?? "127.0.0.1",
          port: proxySettings?.socksServer?.port ?? 6153)
      )
    )

    var additionalServers = [Address.hostPort(host: "192.168.124.1", port: 53)]
    additionalServers.append(
      contentsOf: tunnelNetworkSettings?.dnsSettings?.servers.map {
        Address.hostPort(host: .init($0), port: 53)
      } ?? [])
    dns.$options.withLock {
      $0 = .init(
        group: $0.group,
        logger: $0.logger,
        bindAddress: $0.bindAddress,
        additionalServers: additionalServers,
        mappings: $0.mappings,
        availableIPPool: $0.availableIPPool,
        timeoutInterval: $0.timeoutInterval,
        maxRetryAttempts: $0.maxRetryAttempts
      )
    }

    self.proxySettings = proxySettings
  }

  #if os(macOS)
    public func setSystemProxyEnabled(_ enabled: Bool) async throws {
      do {
        try await PHT.setNWProtocolProxies(
          processName: Foundation.ProcessInfo.processInfo.processName,
          options: enabled ? proxySettings : nil
        )
        if enabled, let proxySettings {
          logger.debug(
            "System configuration has successfully changed the network proxy settings to \(proxySettings)"
          )
        } else {
          logger.debug("System configuration has successfully clear the network proxy settings")
        }
      } catch {
        logger.error("System configuration failed to change network proxy settings \(error)")
      }
    }
  #endif

  public func setLwIPEnabled(_ enabled: Bool, packetFlow: any PacketTunnelFlow) async throws {
    #if NETBOT_REQUIRES_LWIP
      if enabled {
        self.coreLwIP = LwIP(group: group, packetFlow: packetFlow, dns: dns)
        try await self.coreLwIP?.run()
      } else {
        try await self.coreLwIP?.shutdownGracefully()
        self.coreLwIP = nil
      }
    #endif
  }
}
