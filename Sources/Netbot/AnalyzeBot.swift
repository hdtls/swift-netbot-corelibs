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
import NEAddressProcessing
import NIOCore
import NIOSSL
import NetbotLite
import NetbotLiteData
import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import class Foundation.UserDefaults
#else
  import Foundation
#endif

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

#if os(macOS)
  import NetbotDaemons
#endif

/// Assistant to manage PacketTunnelProvider and NIO proxy servers backend.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public actor AnalyzeBot: Actor {

  nonisolated private let core: NetbotLite.AnalyzeBot
  nonisolated private let dns: LocalDNSProxy

  nonisolated public let eventLoopGroup: any EventLoopGroup

  public var logger: Logger = Logger(label: "AnalyzeBot")

  public init(group: any EventLoopGroup = .shared, dns: LocalDNSProxy) {
    self.eventLoopGroup = group
    self.core = .init(group: eventLoopGroup, logger: logger)
    self.dns = dns
  }

  /// Start analyze tunnel.
  public func run() async throws {
    #if os(macOS)
      let toolVersion = try await PHT.toolVersion()
      logger.trace("PHT version: \(toolVersion)")

      await self.core.setProcessInfo(ProcessResolver.shared)
    #endif

    let connectionPublisher = ConnectionPulse(
      group: eventLoopGroup,
      address: .hostPort(host: "127.0.0.1", port: 6170)
    )
    await self.core.setConnectionPublisher(connectionPublisher)
    await self.core.setResolver(dns)
    try await connectionPublisher.run()
    try await self.core.run()
  }

  /// Stop current running analyze tunnel.
  public func shutdownGracefully() async {
    #if os(macOS)
      try? await self.setNWProtocolProxiesOptions(.init())
    #endif
    let connectionPublisher = self.core.connectionPublisher as! ConnectionPulse
    try? await connectionPublisher.shutdownGracefully()
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

  #if os(macOS)
    public func setNWProtocolProxiesOptions(_ options: NEProtocolProxies.Options) async throws {
      do {
        try await PHT.setNWProtocolProxies(
          processName: ProcessInfo.processInfo.processName,
          options: options
        )
        logger.trace("System proxies has been changed to \(options)")
      } catch {
        logger.error("System proxies modification failure with error: \(error)")
      }
    }
  #endif

  /// Modify settings using specific profile.
  public func setProfile(_ newProfile: Profile) async throws {
    try await core.setTunnelNetworkSettings(
      (
        SocketAddress(
          ipAddress: newProfile.httpListenAddress, port: newProfile.httpListenPort ?? 6152),
        SocketAddress(
          ipAddress: newProfile.socksListenAddress, port: newProfile.socksListenPort ?? 6153)
      ))
  }
}
