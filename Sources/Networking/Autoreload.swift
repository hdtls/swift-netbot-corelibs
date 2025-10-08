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

#if canImport(Darwin)
  import Alamofire
  import AnlzrReports
  import Combine
  import Logging
  import NIOConcurrencyHelpers
  import NIOCore
  import Preference
  import _PreferenceSupport
  import _ProfileSupport

  #if canImport(FoundationEssentials)
    import FoundationEssentials
    import FoundationNetworking
  #else
    import Foundation
  #endif

  #if canImport(Network)
    import Network
  #endif

  @available(SwiftStdlib 5.3, *)
  public protocol AutoreloadDelegate: AnyObject, Sendable {
    func autoReloadEnabledHTTPCapabilities(_ capabilities: CapabilityFlags)
    func autoReloadGeoLite2(filePath: String)
    func autoReloadOutboundMode(_ mode: OutboundMode)
    func autoReloadProfile(url: URL, mode: ProxyMode)
  }

  @available(SwiftStdlib 5.3, *)
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

    public weak var delegate: (any AutoreloadDelegate)?

    @LockableTracked public var logger: Logger

    private let eventLoopGroup: any EventLoopGroup

    public init(group: any EventLoopGroup, store: UserDefaults? = .__shared) {
      self.eventLoopGroup = group
      self._logger = .init(Logger(label: "AnalyzerBot-autoreload"))
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
          }
        #endif
        return Session(configuration: configuration)
      }
    }

    public func run() async throws {
      lock.withLock {
        // We use `Date.distantPast` to trigger a force update, so ignore it.
        let autoreload =
          $profileLastContentModificationDate
          .removeDuplicates()
          .combineLatest($forwardingRuleResourcesLastUpdatedDate.removeDuplicates())
          .filter { $0.0 != .distantPast && $0.1 != .distantPast }
          .combineLatest($profileAutoreload)
          // Reload profile only when autoreload is enabled.
          .filter { _, autoreload in autoreload }
          .map { _ in "" }

        $profileURL
          .combineLatest(autoreload.merge(with: $selectionRecords))
          .map(\.0)
          .combineLatest($proxyMode)
          .sink { [weak self] url, mode in
            self?.delegate?.autoReloadProfile(url: url, mode: mode)
          }
          .store(in: &cancellables)

        $maxminddbLastUpdatedDate
          .removeDuplicates()
          .sink { [weak self] _ in
            let filename = "GeoLite2-Country.mmdb"
            let file: String
            if #available(SwiftStdlib 5.7, *) {
              file = URL.maxmind.appending(path: filename).path(percentEncoded: false)
            } else {
              file = URL.maxmind.appendingPathComponent(filename).path
            }
            self?.delegate?.autoReloadGeoLite2(filePath: file)
          }
          .store(in: &cancellables)

        $enabledHTTPCapabilities
          .removeDuplicates()
          .sink { [weak self] capabilities in
            self?.delegate?.autoReloadEnabledHTTPCapabilities(capabilities)
          }
          .store(in: &cancellables)

        $outboundMode
          .removeDuplicates()
          .sink { [weak self] mode in
            self?.delegate?.autoReloadOutboundMode(mode)
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
          let now: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
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
            let now: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
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
      let url = maxminddbDownloadURL
      let filename = "GeoLite2-Country.mmdb"
      let fileURL: URL
      if #available(SwiftStdlib 5.7, *) {
        fileURL = URL.maxmind.appending(path: filename, directoryHint: .notDirectory)
      } else {
        fileURL = URL.maxmind.appendingPathComponent(filename, isDirectory: false)
      }

      let destination: DownloadRequest.Destination = { _, _ in
        (fileURL, [.createIntermediateDirectories, .removePreviousFile])
      }
      try session.download(url, interceptor: .retryPolicy, to: destination)
        .responseURL { [weak self] response in
          guard let self, let url = try? response.result.get() else { return }
          let now: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
          maxminddbLastUpdatedDate =
            (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
            ?? now
        }
    }

    private func downloadForwardingRuleExternalResources() throws {
      Task {
        let profile = try Profile(contentsOf: profileURL)

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

              let _ = try await session.download(
                resourceURL, interceptor: .retryPolicy, to: destination
              )
              .serializingDownloadedFileURL()
              .value
            }
          }
          try await g.waitForAll()
        }

        forwardingRuleResourcesLastUpdatedDate =
          if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
      }
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

  @available(SwiftStdlib 5.3, *)
  extension CapabilityFlags: PreferenceRepresentable {}
#endif
