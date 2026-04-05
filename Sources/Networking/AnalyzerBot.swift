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

import AnlzrReports
import Logging
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore
import NIOSSL
import _PreferenceSupport
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
  import _PrivilegeSupport
#endif

/// Assistant to manage PacketTunnelProvider and NIO proxy servers backend.
@available(SwiftStdlib 5.3, *)
public actor AnalyzerBot: Actor {

  nonisolated private let core: Analyzer

  nonisolated public let eventLoopGroup: any EventLoopGroup

  public var logger: Logger = Logger(label: "AnalyzerBot")

  public init(group: any EventLoopGroup = .shared, dns: LocalDNSProxy) {
    self.eventLoopGroup = group

    core = Analyzer(group: eventLoopGroup, logger: logger)

    core.services.dns.use { _ in dns }

    let pulse = ConnectionPulse(
      group: eventLoopGroup,
      address: .hostPort(host: "127.0.0.1", port: 6170)
    )
    core.services.connectionTrasmission.use { _ in pulse }

    #if os(macOS)
      core.services.processReport.use { _ in ProcessResolver.shared }
    #endif
  }

  /// Start analyzer tunnel.
  public func run() async throws {
    #if os(macOS)
      let toolVersion = try await PHT.toolVersion()
      logger.trace("PHT version: \(toolVersion)")
    #endif
    try await self.core.run()
  }

  /// Stop current running analyzer tunnel.
  public func shutdownGracefully() async {
    #if os(macOS)
      try? await self.setNWProtocolProxiesOptions(.init())
    #endif
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
