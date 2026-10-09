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
import NetbotNIO
import NetbotProfile
import Synchronization

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
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
@available(SwiftStdlib 6.0, *)
public actor AnalyzeBot {

  nonisolated private let core: NetbotLite.AnalyzeBot
  nonisolated public let dns: LocalDNSProxy
  nonisolated public let group: any EventLoopGroup
  public var logger: Logger = Logger(label: "AnalyzeBot")

  private var proxySettings: NEProxySettings?

  public init(group: any EventLoopGroup = .default) {
    self.group = group
    self.dns = .init(group: group)
    self.core = .init(group: group, logger: logger)
  }

  /// Start analyze tunnel.
  public func run() async throws {
    let publisher = ConnectionPulse(group: group, address: .hostPort(host: "127.0.0.1", port: 6170))
    await self.core.setConnectionPublisher(publisher)
    await self.core.setDNSResolver(dns)

    try await withThrowingDiscardingTaskGroup { g in
      g.addTask {
        try await publisher.run()
      }
      g.addTask {
        try await self.dns.run()
      }
      g.addTask {
        try await self.core.run()
      }
    }
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
        .hostPort(
          host: .init(proxySettings?.httpsServer?.address ?? "127.0.0.1"),
          port: .init(rawValue: UInt16(proxySettings?.httpsServer?.port ?? 6152))
        ),
        .hostPort(
          host: .init(proxySettings?.socksServer?.address ?? "127.0.0.1"),
          port: .init(rawValue: UInt16(proxySettings?.socksServer?.port ?? 1080))
        )
      )
    )

    var additionalServers = [Address.hostPort(host: "116.116.116.116", port: 53)]
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
        try await PHTSession.shared.setNWProtocolProxies(
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
}
