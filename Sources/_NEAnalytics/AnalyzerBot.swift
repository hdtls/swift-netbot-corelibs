//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Logging
import MaxMindDB
import NEAddressProcessing
import NIOConcurrencyHelpers
import NIOCore
import NIOSSL
import _PersistentStore
import _ResourceProcessing

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
  import NEXPCService
#endif

/// Assistant to manage PacketTunnelProvider and NIO proxy servers backend.
@globalActor public actor AnalyzerBot {

  public static let shared = AnalyzerBot()

  nonisolated private let core: Analyzer

  nonisolated public let eventLoopGroup: any EventLoopGroup
  nonisolated public let logger = Logger(label: "AnalyzerBot")

  private var maxminddb: MaxMindDB?

  private var processName: String { ProcessInfo.processInfo.processName }

  private init() {
    eventLoopGroup = MultiThreadedEventLoopGroup.shared

    let dbFilename = "GeoLite2-Country.mmdb"

    #if canImport(Darwin)
      if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
        maxminddb = try? MaxMindDB(
          file: URL.maxmind.appending(path: dbFilename).path(percentEncoded: false),
          mode: .mmap
        )
      } else {
        maxminddb = try? MaxMindDB(
          file: URL.maxmind.appendingPathComponent(dbFilename).path,
          mode: .mmap
        )
      }
    #else
      maxminddb = try? MaxMindDB(
        file: URL.maxmind.appending(path: dbFilename).path(percentEncoded: false),
        mode: .mmap
      )
    #endif

    core = Analyzer(group: eventLoopGroup, logger: logger)

    let pulse = ConnectionPulse(
      group: eventLoopGroup,
      address: .hostPort(host: "127.0.0.1", port: 6170)
    )
    core.services.connectionTrasmission.use { _ in pulse }

    #if os(macOS)
      core.services.processReport.use { _ in PHT }
    #endif
  }

  /// Start analyzer tunnel.
  nonisolated public func startVPNTunnel() async throws {
    #if os(macOS) && DEBUG
      // TODO: REMOVE AFTER DAEMON DEVELOPMENT FINISHED
      try? await PHT.invalidate()
    #endif

    try await self.core.run()
  }

  /// Stop current running analyzer tunnel.
  nonisolated public func stopVPNTunnel() async {
    try? await self.core.shutdownGracefully()
  }

  /// Modify MaxMind GeoLite2-Country.mmdb.
  public func setGeoLite2DB(_ db: MaxMindDB) async {
    maxminddb = db

    // GEOIP rules are affected by the GeoLite2 country database, so
    // we need reload rules.
    await setForwardingRules(core.forwardingRules)
  }

  /// Modify Web and SOCKS proxy settings.
  private func setTunnelNetworkSettings(_ networkSettings: Analyzer.NetworkSettings) async throws {
    try await core.setTunnelNetworkSettings(networkSettings)
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
    let forwardingRules: [any ForwardingRuleConvertible] = forwardingRules.map {
      if var forwardingRule = $0 as? GeoIPForwardingRule {
        forwardingRule.db = maxminddb
        return forwardingRule
      }

      if var forwardingRule = $0 as? RulesetForwardingRule {
        let externalRules: [any ForwardingRule] = forwardingRule.externalRules.map {
          guard var element = $0 as? GeoIPForwardingRule else {
            return $0
          }
          element.db = maxminddb
          return element
        }
        forwardingRule.externalRules = externalRules
        return forwardingRule
      }

      return $0
    }
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
    try await setTunnelNetworkSettings(
      (
        SocketAddress(
          ipAddress: newProfile.httpListenAddress, port: newProfile.httpListenPort ?? 6152),
        SocketAddress(
          ipAddress: newProfile.socksListenAddress, port: newProfile.socksListenPort ?? 6153)
      ))

    await setForwardProtocol(newProfile.asForwardProtocol())
    await setForwardingRules(newProfile.asForwardingRules())
    try await setDecryptionSSLPKCS12Bundle(newProfile.asDecryptionPKCS12Bundle())
  }
}
