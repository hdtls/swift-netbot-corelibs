//
// See LICENSE.txt for license information
//

public import Anlzr
private import AnlzrReports
import Logging
public import MaxMindDB
private import NIOConcurrencyHelpers
public import _ResourceProcessing

#if canImport(Darwin)
  private import Foundation
#else
  private import FoundationEssentials
  private import class Foundation.UserDefaults
#endif

#if canImport(Darwin)
  private import UserNotifications
#endif

/// Assistant to manage PacketTunnelProvider and NIO proxy servers backend.
@globalActor public actor AnalyzerBot {

  public static let shared = AnalyzerBot()

  nonisolated private let analyzer: Analyzer

  nonisolated public let logger: Logger

  private var maxminddb: MaxMindDB?

  private init() {
    LoggingSystem.bootstrap { label in
      var handler: any Logging.LogHandler
      #if canImport(Darwin)
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
          handler = LogHandler(label: label)
        } else {
          handler = StreamLogHandler.standardOutput(label: label)
        }
      #else
        handler = StreamLogHandler.standardOutput(label: label)
      #endif
      if let rawValue = UserDefaults.applicationGroup?.string(forKey: Prefs.Name.logLevel) {
        handler.logLevel = .init(rawValue: rawValue) ?? .info
      }
      return handler
    }

    logger = .init(label: "AnalyzerBot")
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
    await setForwardingRules(profile.asForwardingRules())
  }

  /// Modify outbound mode.
  public func setOutboundMode(_ outboundMode: OutboundMode) async {
    guard outboundMode != analyzer.outboundMode else { return }

    await self.analyzer.setOutboundMode(outboundMode)
    logger.info("Outbound mode has been changed to \(outboundMode.localizedName)")

    #if canImport(Darwin)
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

  /// Modify enabled HTTP capabilities.
  public func setEnabledHTTPCapabilities(_ enabledHTTPCapabilities: CapabilityFlags) async {
    await self.analyzer.setEnabledHTTPCapabilities(enabledHTTPCapabilities)
  }

  /// Modify current analyzer settings using specific profile.
  public func setProfile(_ newProfile: Profile) async throws {
    await setForwardProtocol(newProfile.asForwardProtocol())
    await setForwardingRules(newProfile.asForwardingRules())

    try await setTunnelNetworkSettings((
      SocketAddress(ipAddress: newProfile.httpListenAddress, port: newProfile.httpListenPort ?? 6152),
      SocketAddress(ipAddress: newProfile.socksListenAddress, port: newProfile.socksListenPort ?? 6153)
    ))
  }

  private func setTunnelNetworkSettings(_ addresses: (webProxyListenAddress: SocketAddress, socksProxyListenAddress: SocketAddress)) async throws {
    try await analyzer.setTunnelNetworkSettings(addresses)
  }

  public func setForwardProtocol(_ forwardProtocol: any ForwardProtocolConvertible) async {
    await analyzer.setForwardProtocol(forwardProtocol)
  }

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
}
