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

#if canImport(Darwin)
  import Alamofire
  import NetbotDNS
  import NetbotLite
  import NetbotLiteData
  import Combine
  import Foundation
  import Logging
  import MaxMindDB
  import NIOCore
  import NIOSSL
  import Preference
  import NetbotPreferences
  import NetbotProfile

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  #if canImport(Network)
    import Network
  #endif

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  public protocol ProfileAutoreloadDelegate: AnyObject, Sendable {
    func setEnabledHTTPCapabilities(_ capabilities: CapabilityFlags) async
    func setForwardProtocol(_ forwardProtocol: any ForwardProtocolConvertible) async
    func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) async
    func setOutboundMode(_ mode: OutboundMode) async
    func setDecryptionPKCS12Bundle(_ bundle: NIOSSLPKCS12Bundle?) async
    func setTunnelNetworkSettings(_ profile: Profile, mode: ProxyMode) async throws
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @MainActor final public class ProfileAutoreload {

    @Preference(Prefs.Name.profileURL, store: .__shared)
    public var profileURL = URL.profile

    @Preference(Prefs.Name.profileLastContentModificationDate, store: .__shared)
    public var profileLastContentModificationDate = Date.distantFuture

    @Preference(Prefs.Name.profileAutoreload, store: .__shared)
    public var profileAutoreload = false

    @Preference(Prefs.Name.proxyMode, store: .__shared)
    public var proxyMode: ProxyMode = [.webProxy]

    @Preference(Prefs.Name.outboundMode, store: .__shared)
    public var outboundMode = OutboundMode.direct

    @Preference(Prefs.Name.enabledHTTPCapabilities, store: .__shared)
    public var enabledHTTPCapabilities = CapabilityFlags()

    @Preference(Prefs.Name.selectionRecordForGroups, store: .__shared)
    public var selectionRecords = "{}"

    @Preference(Prefs.Name.maxminddbDownloadURL, store: .__shared)
    public var maxminddbDownloadURL = URL(string: "https://git.io/GeoLite2-Country.mmdb")!

    @Preference(Prefs.Name.maxminddbLastUpdatedDate, store: .__shared)
    public var maxminddbLastUpdatedDate = Date.distantFuture

    @Preference(Prefs.Name.maxminddbKeepUpToDate, store: .__shared)
    public var maxminddbKeepUpToDate = true

    @Preference(Prefs.Name.forwardingRuleResourcesLastUpdatedDate, store: .__shared)
    public var forwardingRuleResourcesLastUpdatedDate = Date.distantFuture

    private var cancellables = Set<AnyCancellable>()
    private var maxminddbAutoreload: Scheduled<Task<Void, any Error>>?
    private var externalRulesAutoreload: Scheduled<Task<Void, any Error>>?

    public weak var delegate: (any ProfileAutoreloadDelegate)?

    public let logger = Logger(label: "AnalyzeBot-autoreload")

    private let group: any EventLoopGroup

    private var maxminddbFile: String {
      let filename = "GeoLite2-Country.mmdb"
      let filePath = URL.maxmind.appending(path: filename, directoryHint: .notDirectory).path(
        percentEncoded: false)
      return filePath
    }

    public init(group: any EventLoopGroup = .shared, store: UserDefaults?) {
      self.group = group
      self._profileURL = .init(wrappedValue: .profile, Prefs.Name.profileURL, store: store)
      self._profileLastContentModificationDate = .init(
        wrappedValue: .distantFuture,
        Prefs.Name.profileLastContentModificationDate,
        store: store
      )
      self._profileAutoreload = .init(
        wrappedValue: false,
        Prefs.Name.profileAutoreload,
        store: store
      )
      self._proxyMode = .init(wrappedValue: [.webProxy], Prefs.Name.proxyMode, store: store)
      self._outboundMode = .init(wrappedValue: .direct, Prefs.Name.outboundMode, store: store)
      self._enabledHTTPCapabilities = .init(
        wrappedValue: [],
        Prefs.Name.enabledHTTPCapabilities,
        store: store
      )
      self._selectionRecords = .init(
        wrappedValue: "{}",
        Prefs.Name.selectionRecordForGroups,
        store: store
      )
      self._maxminddbDownloadURL = .init(
        wrappedValue: URL(string: "https://git.io/GeoLite2-Country.mmdb")!,
        Prefs.Name.maxminddbDownloadURL,
        store: store
      )
      self._maxminddbLastUpdatedDate = .init(
        wrappedValue: .distantFuture,
        Prefs.Name.maxminddbLastUpdatedDate,
        store: store
      )
      self._maxminddbKeepUpToDate = .init(
        wrappedValue: true,
        Prefs.Name.maxminddbKeepUpToDate,
        store: store
      )
      self._forwardingRuleResourcesLastUpdatedDate = .init(
        wrappedValue: .distantFuture,
        Prefs.Name.forwardingRuleResourcesLastUpdatedDate,
        store: store
      )
    }

    nonisolated public init(group: any EventLoopGroup = .shared) {
      self.group = group
    }

    private var session: Session {
      get throws {
        let profile = try Profile(contentsOf: profileURL)
        let configuration = URLSessionConfiguration.default
        #if canImport(Network)
          configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

          if let httpListenPort = profile.httpListenPort,
            let port = NWEndpoint.Port(rawValue: UInt16(httpListenPort))
          {
            configuration.proxyConfigurations = [
              .init(
                httpCONNECTProxy: .hostPort(host: .init(profile.httpListenAddress), port: port))
            ]
          }
        #endif
        return Session(configuration: configuration)
      }
    }

    public func run() async throws {
      let profile = try Profile(contentsOf: profileURL)
      await delegate?.setOutboundMode(outboundMode)
      await delegate?.setEnabledHTTPCapabilities(enabledHTTPCapabilities)
      await delegate?.setForwardProtocol(profile.asForwardProtocol())
      await delegate?.setDecryptionPKCS12Bundle(try? profile.asDecryptionPKCS12Bundle())
      await setForwardingRules(profile.asForwardingRules())
      try await delegate?.setTunnelNetworkSettings(profile, mode: proxyMode)

      $profileURL
        .combineLatest($proxyMode, $profileLastContentModificationDate, $selectionRecords)
        .dropFirst()
        .map { ($0.0, $0.1) }
        .sink { url, mode in
          Task { [weak self] in
            guard let self, let profile = try? Profile(contentsOf: url) else { return }
            await setForwardingRules(profile.asForwardingRules())
            await delegate?.setForwardProtocol(profile.asForwardProtocol())
            await delegate?.setDecryptionPKCS12Bundle(try? profile.asDecryptionPKCS12Bundle())
            try? await delegate?.setTunnelNetworkSettings(profile, mode: mode)
          }
        }
        .store(in: &cancellables)

      $enabledHTTPCapabilities
        .dropFirst()
        .sink { capabilities in
          Task { [weak self] in
            guard let self else { return }
            await delegate?.setEnabledHTTPCapabilities(capabilities)
          }
        }
        .store(in: &cancellables)

      $outboundMode
        .dropFirst()
        .sink { mode in
          Task { [weak self] in
            guard let self else { return }
            await delegate?.setOutboundMode(mode)
          }
        }
        .store(in: &cancellables)

      // Maxmind db auto update.
      $maxminddbDownloadURL.combineLatest($maxminddbLastUpdatedDate, $maxminddbKeepUpToDate)
        .sink { [weak self] url, date, keepUpToDate in
          guard let self else { return }
          guard keepUpToDate else {
            // Cancel auto update task.
            maxminddbAutoreload?.cancel()
            return
          }
          let now = Date.now
          let timeIntervalPast = date > now ? 86400 * 7 : Int64(now.timeIntervalSince(date))
          let initialDelay = TimeAmount.seconds(max(0, 86400 * 7 - timeIntervalPast))
          maxminddbAutoreload?.cancel()
          maxminddbAutoreload = group.next().scheduleTask(deadline: .now() + initialDelay) {
            Task { try await self.downloadMaxmindDBs(url) }
          }
        }
        .store(in: &cancellables)

      // External forwarding rule resources auto update.
      $forwardingRuleResourcesLastUpdatedDate
        .sink { [weak self] date in
          guard let self else { return }
          let now = Date.now
          let timeIntervalPast = date > now ? 24 * 3600 : Int64(now.timeIntervalSince(date))
          let initialDelay = TimeAmount.seconds(max(0, 24 * 60 * 60 - timeIntervalPast))
          externalRulesAutoreload?.cancel()
          externalRulesAutoreload = group.next().scheduleTask(deadline: .now() + initialDelay) {
            Task { try await self.downloadExternalRules() }
          }
        }
        .store(in: &cancellables)
    }

    #if swift(>=6.2)
      @concurrent private func downloadMaxmindDBs(_ url: URL) async throws {
        try await _downloadMaxmindDBs(url)
      }
    #else
      nonisolated private func downloadMaxmindDBs(_ url: URL) async throws {
        try await _downloadMaxmindDBs(url)
      }
    #endif
    nonisolated private func _downloadMaxmindDBs(_ url: URL) async throws {
      let session = try await self.session
      let fileURL = await URL(fileURLWithPath: maxminddbFile)

      let destination: DownloadRequest.Destination = { _, _ in
        (fileURL, [.createIntermediateDirectories, .removePreviousFile])
      }
      _ = try await session.download(url, interceptor: .retryPolicy, to: destination)
        .serializingDownloadedFileURL()
        .value

      let now = Date.now
      let maxminddbLastUpdatedDate =
        (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey])
          .contentModificationDate)
        ?? now

      await MainActor.run {
        self.maxminddbLastUpdatedDate = maxminddbLastUpdatedDate
      }

      let profile = try await Profile(contentsOf: profileURL)
      await setForwardingRules(profile.asForwardingRules())
    }

    #if swift(>=6.2)
      @concurrent private func downloadExternalRules() async throws {
        try await _downloadExternalRules()
      }
    #else
      nonisolated private func downloadExternalRules() async throws {
        try await _downloadExternalRules()
      }
    #endif
    nonisolated private func _downloadExternalRules() async throws {
      var profile = try await Profile(contentsOf: profileURL)

      try await withThrowingTaskGroup(of: Void.self) { g in
        let session = try await self.session

        for forwardingRuleConvertible in profile.asForwardingRules() {
          let dstURL: URL
          let resourceURL: URL?

          switch forwardingRuleConvertible {
          case let forwardingRule as DomainsetForwardingRule:
            resourceURL = URL(string: forwardingRule.originalURLString)
            dstURL = forwardingRule.externalResourceURL
          case let forwardingRule as RulesetForwardingRule:
            resourceURL = URL(string: forwardingRule.originalURLString)
            dstURL = forwardingRule.externalResourceURL
          default:
            continue
          }

          guard let resourceURL, !resourceURL.isFileURL else {
            continue
          }

          g.addTask {
            let destination: DownloadRequest.Destination = { _, _ in
              (dstURL, [.createIntermediateDirectories, .removePreviousFile])
            }

            _ = try await session.download(
              resourceURL, interceptor: .retryPolicy, to: destination
            )
            .serializingDownloadedFileURL()
            .value
          }
        }
        try await g.waitForAll()
      }

      await MainActor.run {
        forwardingRuleResourcesLastUpdatedDate = Date.now
      }

      profile = try await Profile(contentsOf: profileURL)
      await delegate?.setForwardingRules(profile.asForwardingRules())
    }

    private func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) async {
      let maxminddb = try? MaxMindDB(file: maxminddbFile, mode: .mmap)
      await delegate?.setForwardingRules(
        forwardingRules.map {
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
      )
    }

    public func shutdownGracefully() async {
      cancellables = []
      maxminddbAutoreload?.cancel()
      externalRulesAutoreload?.cancel()
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension CapabilityFlags: PreferenceRepresentable {}
#endif
