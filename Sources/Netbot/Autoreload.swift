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
  import NetbotLite
  import NetbotLiteData
  import Combine
  import Foundation
  import Logging
  import MaxMindDB
  import NIOConcurrencyHelpers
  import NIOCore
  import NIOSSL
  import Preference
  import _PreferenceSupport
  import _ProfileSupport

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  #if canImport(Network)
    import Network
  #endif

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  public protocol AutoreloadDelegate: AnyObject, Sendable {
    func autoReloadEnabledHTTPCapabilities(_ capabilities: CapabilityFlags) async
    func autoReloadForwardProtocol(_ forwardProtocol: any ForwardProtocolConvertible) async
    func autoReloadForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) async
    func autoReloadOutboundMode(_ mode: OutboundMode) async
    func autoReloadProfile(_ profile: Profile, mode: ProxyMode) async
    func autoReloadDecryptionPKCS12Bundle(_ bundle: NIOSSLPKCS12Bundle?) async
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  final public class AutoreloadSubscription: @unchecked Sendable {

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
    private var existingGeoLite2AutoUpdateTask: RepeatedTask?
    private var existingForwardingRulesAutoUpdateTask: RepeatedTask?

    private let lock = NIOLock()

    @LockableTracked public weak var delegate: (any AutoreloadDelegate)?

    @LockableTracked public var logger: Logger

    @LockableTracked private var maxminddb: MaxMindDB?

    private let eventLoopGroup: any EventLoopGroup

    private var maxminddbFile: String {
      let filename = "GeoLite2-Country.mmdb"
      let filePath: String
      #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
        if #available(SwiftStdlib 5.7, *) {
          filePath = URL.maxmind.appending(path: filename, directoryHint: .notDirectory).path(
            percentEncoded: false)
        } else {
          filePath = URL.maxmind.appendingPathComponent(filename, isDirectory: false).path
        }
      #else
        filePath = URL.maxmind.appending(path: filename, directoryHint: .notDirectory).path(
          percentEncoded: false)
      #endif
      return filePath
    }

    public init(group: any EventLoopGroup = .shared, store: UserDefaults? = .__shared) {
      self.eventLoopGroup = group
      self._delegate = .init(nil)
      self._logger = .init(Logger(label: "AnalyzeBot-autoreload"))
      self._maxminddb = .init(nil)
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

    private var session: Session {
      get throws {
        let profile = try Profile(contentsOf: profileURL)
        let configuration = URLSessionConfiguration.default
        #if canImport(Network)
          configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

          if let httpListenPort = profile.httpListenPort,
            let port = NWEndpoint.Port(rawValue: UInt16(httpListenPort))
          {
            #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
              if #available(SwiftStdlib 5.9, *) {
                configuration.proxyConfigurations = [
                  .init(
                    httpCONNECTProxy: .hostPort(host: .init(profile.httpListenAddress), port: port))
                ]
              } else {
                configuration.connectionProxyDictionary = [
                  kCFNetworkProxiesHTTPEnable as String: 1,
                  kCFNetworkProxiesHTTPProxy as String: profile.httpListenAddress,
                  kCFNetworkProxiesHTTPPort as String: port.rawValue,
                ]
              }
            #else
              configuration.proxyConfigurations = [
                .init(
                  httpCONNECTProxy: .hostPort(host: .init(profile.httpListenAddress), port: port))
              ]
            #endif
          }
        #endif
        return Session(configuration: configuration)
      }
    }

    public func run() async throws {
      maxminddb = try MaxMindDB(file: maxminddbFile, mode: .mmap)
      let profile = try Profile(contentsOf: profileURL)
      await setOutboundMode(outboundMode)
      await setProfile(profile, mode: proxyMode)
      await setEnabledHTTPCapabilities(enabledHTTPCapabilities)

      lock.withLock {
        $profileURL
          .combineLatest($proxyMode, $profileLastContentModificationDate, $selectionRecords)
          .dropFirst()
          .sink { [weak self] url, mode, _, _ in
            guard let self, let profile = try? Profile(contentsOf: url) else { return }
            Task {
              await setProfile(profile, mode: mode)
            }
          }
          .store(in: &cancellables)

        $enabledHTTPCapabilities
          .removeDuplicates()
          .dropFirst()
          .sink { [weak self] capabilities in
            guard let self else { return }
            Task {
              await setEnabledHTTPCapabilities(capabilities)
            }
          }
          .store(in: &cancellables)

        $outboundMode
          .removeDuplicates()
          .dropFirst()
          .sink { [weak self] mode in
            guard let self else { return }
            Task {
              await setOutboundMode(mode)
            }
          }
          .store(in: &cancellables)

        // Maxmind db auto update.
        Publishers.CombineLatest3(
          $maxminddbDownloadURL.removeDuplicates(),
          $maxminddbLastUpdatedDate.removeDuplicates(),
          $maxminddbKeepUpToDate.removeDuplicates()
        )
        .sink { [weak self] _, date, keepUpToDate in
          guard let self else { return }
          guard keepUpToDate else {
            // Cancel auto update task.
            existingGeoLite2AutoUpdateTask?.cancel()
            return
          }

          #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
            let now: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
          #else
            let now = Date.now
          #endif
          let timeIntervalPast = date > now ? 86400 * 7 : Int64(now.timeIntervalSince(date))
          let initialDelay = TimeAmount.seconds(max(0, 86400 * 7 - timeIntervalPast))
          let delay = TimeAmount.hours(24 * 7)
          existingGeoLite2AutoUpdateTask?.cancel()
          existingGeoLite2AutoUpdateTask =
            eventLoopGroup
            .any()
            .scheduleRepeatedTask(initialDelay: initialDelay, delay: delay) { _ in
              try self.downloadMaxmindDBs()
            }
        }
        .store(in: &cancellables)

        // External forwarding rule resources auto update.
        $forwardingRuleResourcesLastUpdatedDate
          .removeDuplicates()
          .sink { [weak self] date in
            guard let self else { return }
            #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
              let now: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
            #else
              let now = Date.now
            #endif
            let timeIntervalPast = date > now ? 24 * 3600 : Int64(now.timeIntervalSince(date))
            let initialDelay = TimeAmount.seconds(max(0, 24 * 60 * 60 - timeIntervalPast))
            let delay = TimeAmount.hours(24)
            existingForwardingRulesAutoUpdateTask?.cancel()
            existingForwardingRulesAutoUpdateTask =
              eventLoopGroup
              .any()
              .scheduleRepeatedTask(initialDelay: initialDelay, delay: delay) { _ in
                try self.downloadForwardingRuleExternalResources()
              }
          }
          .store(in: &cancellables)
      }
    }

    private func downloadMaxmindDBs() throws {
      let session = try self.session
      let url = maxminddbDownloadURL
      let fileURL = URL(fileURLWithPath: maxminddbFile)
      Task {
        let destination: DownloadRequest.Destination = { _, _ in
          (fileURL, [.createIntermediateDirectories, .removePreviousFile])
        }
        _ = try await session.download(url, interceptor: .retryPolicy, to: destination)
          .serializingDownloadedFileURL()
          .value

        #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
          let now: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
        #else
          let now = Date.now
        #endif
        maxminddbLastUpdatedDate =
          (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey])
            .contentModificationDate)
          ?? now

        let profile = try Profile(contentsOf: profileURL)
        await setForwardingRules(profile.asForwardingRules())
      }
    }

    private func downloadForwardingRuleExternalResources() throws {
      Task {
        var profile = try Profile(contentsOf: profileURL)

        try await withThrowingTaskGroup(of: Void.self) { g in
          let session = try self.session

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

        #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
          forwardingRuleResourcesLastUpdatedDate =
            if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
        #else
          forwardingRuleResourcesLastUpdatedDate = Date.now
        #endif

        profile = try Profile(contentsOf: profileURL)
        await setForwardingRules(profile.asForwardingRules())
      }
    }

    private func setProfile(_ profile: Profile, mode: ProxyMode) async {
      await setForwardingRules(profile.asForwardingRules())
      await delegate?.autoReloadProfile(profile, mode: mode)
      await delegate?.autoReloadForwardProtocol(profile.asForwardProtocol())
      await delegate?.autoReloadDecryptionPKCS12Bundle(try? profile.asDecryptionPKCS12Bundle())
    }

    private func setOutboundMode(_ mode: OutboundMode) async {
      await delegate?.autoReloadOutboundMode(mode)
    }

    private func setEnabledHTTPCapabilities(_ capabilities: CapabilityFlags) async {
      await delegate?.autoReloadEnabledHTTPCapabilities(capabilities)
    }

    private func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) async {
      await delegate?.autoReloadForwardingRules(
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
        })
    }

    public func shutdownGracefully() async {
      lock.withLock {
        for cancellable in cancellables {
          cancellable.cancel()
        }
        cancellables.removeAll()
      }
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension CapabilityFlags: PreferenceRepresentable {}
#endif
