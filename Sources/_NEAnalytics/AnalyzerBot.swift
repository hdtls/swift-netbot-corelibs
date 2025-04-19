//
// See LICENSE.txt for license information
//

import Anlzr
import AnlzrReports
import Logging
import MaxMindDB
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

#if canImport(UserNotifications)
  import UserNotifications
#endif

/// Assistant to manage PacketTunnelProvider and NIO proxy servers backend.
@globalActor public actor AnalyzerBot {

  public static let shared = AnalyzerBot()

  nonisolated private let analyzer: Analyzer

  nonisolated public let logger = Logger(label: "AnalyzerBot")

  private var maxminddb: MaxMindDB?

  private init() {
    var reporting: any ConnectionReporting = NoOpReporting()

    let containerURL = URL.applicationGroupDirectory
    let filename = "GeoLite2-Country.mmdb"
    let persistentStorage: URL
    let dbPath: String
    #if canImport(Darwin)
      let pathComponent = "/Library/Caches/Netbot/analyzed.store"
      if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
        persistentStorage = containerURL.appending(component: pathComponent)
        dbPath = URL.maxmind.appending(path: filename).path(percentEncoded: false)
      } else {
        persistentStorage = containerURL.appendingPathComponent(pathComponent)
        dbPath = URL.maxmind.appendingPathComponent(filename).path
      }
    #else
      let pathComponent = "~/.cache/com.tenbits.netbot/analyzed.store"
      persistentStorage = containerURL.appending(component: pathComponent)
      dbPath = URL.maxmind.appending(path: filename).path(percentEncoded: false)
    #endif
    reporting = Analyzed(persistentStorage: persistentStorage)
    maxminddb = try? MaxMindDB(file: dbPath, mode: .mmap)

    analyzer = Analyzer(logger: logger, reporter: reporting)
  }

  /// Start analyzer tunnel.
  nonisolated public func startVPNTunnel() async throws {
    try await self.analyzer.run()
  }

  /// Stop current running analyzer tunnel.
  nonisolated public func stopVPNTunnel() async {
    do {
      try await self.analyzer.shutdownGracefully()
    } catch {}
  }

  /// Modify MaxMind GeoLite2-Country.mmdb.
  public func setGeoLite2DB(_ db: MaxMindDB) async throws {
    maxminddb = db
    await setForwardingRules(analyzer.forwardingRules)
  }

  /// Modify Web and SOCKS proxy settings.
  private func setTunnelNetworkSettings(_ networkSettings: Analyzer.NetworkSettings) async throws {
    try await analyzer.setTunnelNetworkSettings(networkSettings)
  }

  /// Modify outbound mode.
  public func setOutboundMode(_ outboundMode: OutboundMode) async {
    guard outboundMode != analyzer.outboundMode else { return }

    await self.analyzer.setOutboundMode(outboundMode)
    logger.info("Outbound mode has been changed to \(outboundMode.localizedName)")

    #if canImport(UserNotifications)
      Task.detached {
        let content = UNMutableNotificationContent()
        content.title = String(
          localized: "Outbound Mode Changed",
          comment: "The title for outbound mode change notification"
        )
        switch outboundMode {
        case .direct:
          content.body = String(
            localized: "The outbound mode has been changed to Direct Outbound",
            comment: "Outbound mode changed to Direct notification body"
          )
        case .globalProxy:
          content.body = String(
            localized: "The outbound mode has been changed to Global Proxy",
            comment: "Outbound mode changed to Proxy notification body"
          )
        case .ruleBased:
          content.body = String(
            localized: "The outbound mode has been changed to Rule-based Proxy",
            comment: "Outbound mode changed to Rule-based notification body"
          )
        }

        let notification = UNNotificationRequest(
          identifier: content.title,
          content: content,
          trigger: nil
        )
        await UNUserNotificationCenter.default.post(notification)
      }
    #endif
  }

  /// Modify global forward protocol.
  public func setForwardProtocol(_ forwardProtocol: any ForwardProtocolConvertible) async {
    await analyzer.setForwardProtocol(forwardProtocol)
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
    await analyzer.setForwardingRules(forwardingRules)
  }

  /// Modify enabled HTTP capabilities.
  public func setEnabledHTTPCapabilities(_ enabledHTTPCapabilities: CapabilityFlags) async {
    await self.analyzer.setEnabledHTTPCapabilities(enabledHTTPCapabilities)
  }

  /// Modify HTTPS decryption PKCS#12 bundle.
  public func setDecryptionSSLPKCS12Bundle(_ sslPKCS12Bundle: NIOSSLPKCS12Bundle?) async {
    guard sslPKCS12Bundle != analyzer.decryptionSSLPKCS12Bundle else { return }

    await self.analyzer.setDecryptionSSLPKCS12Bundle(sslPKCS12Bundle)
  }

  /// Modify current analyzer settings using specific profile.
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
