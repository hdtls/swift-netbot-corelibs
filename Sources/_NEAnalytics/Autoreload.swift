//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Anlzr
  import Combine
  import Logging
  import NIOConcurrencyHelpers
  import NIOCore
  import Preference
  import _PersistentStore
  import _ResourceProcessing

  #if canImport(FoundationEssentials)
    import FoundationEssentials
    import FoundationNetworking
  #else
    import Foundation
  #endif

  #if canImport(Network)
    import Network
  #endif

  public protocol AutoreloadDelegate: AnyObject, Sendable {
    func autoReloadEnabledHTTPCapabilities(_ capabilities: CapabilityFlags)
    func autoReloadGeoLite2(filePath: String)
    func autoReloadOutboundMode(_ mode: OutboundMode)
    func autoReloadProfile(url: URL, mode: ProxyMode)
  }

  final public class AutoreloadSubscription: @unchecked Sendable {

    @Preference(Prefs.Name.profileURL, store: .applicationGroup)
    public var profileURL = URL.profile

    @Preference(Prefs.Name.profileLastContentModificationDate, store: .applicationGroup)
    public var profileLastContentModificationDate = Date.distantFuture

    @Preference(Prefs.Name.profileAutoreload, store: .applicationGroup)
    public var profileAutoreload = false

    @Preference(Prefs.Name.proxyMode, store: .applicationGroup)
    public var proxyMode: ProxyMode = [.webProxy]

    @Preference(Prefs.Name.outboundMode, store: .applicationGroup)
    public var outboundMode = OutboundMode.direct

    @Preference(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
    public var enabledHTTPCapabilities = CapabilityFlags()

    @Preference(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
    public var selectionRecords = "{}"

    @Preference(Prefs.Name.maxminddbDownloadURL, store: .applicationGroup)
    public var maxminddbDownloadURL = URL(string: "https://git.io/GeoLite2-Country.mmdb")!

    @Preference(Prefs.Name.maxminddbLastUpdatedDate, store: .applicationGroup)
    public var maxminddbLastUpdatedDate = Date.distantFuture

    @Preference(Prefs.Name.maxminddbKeepUpToDate, store: .applicationGroup)
    public var maxminddbKeepUpToDate = true

    @Preference(Prefs.Name.forwardingRuleResourcesLastUpdatedDate, store: .applicationGroup)
    public var forwardingRuleResourcesLastUpdatedDate = Date.distantFuture

    private var cancellables = Set<AnyCancellable>()
    private var existingGeoLite2AutoUpdateTask: RepeatedTask?
    private var existingForwardingRulesAutoUpdateTask: RepeatedTask?

    private let lock = NIOLock()

    public weak var delegate: (any AutoreloadDelegate)?

    private let logger: Logger
    private let eventLoopGroup: any EventLoopGroup

    public init(
      group: any EventLoopGroup,
      logger: Logger,
      store: UserDefaults? = .applicationGroup
    ) {
      self.eventLoopGroup = group
      self.logger = logger
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
        wrappedValue: false,
        Prefs.Name.maxminddbKeepUpToDate,
        store: store
      )
      self._forwardingRuleResourcesLastUpdatedDate = .init(
        wrappedValue: .distantFuture,
        Prefs.Name.forwardingRuleResourcesLastUpdatedDate,
        store: store
      )
    }

    private func _session(host: String, port: UInt16) -> URLSession {
      let configuration = URLSessionConfiguration.default
      #if canImport(Network)
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
          configuration.proxyConfigurations = [
            .init(
              httpCONNECTProxy: .hostPort(
                host: .init(host), port: .init(rawValue: port) ?? 6152)
            )
          ]
        } else {
          configuration.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPEnable as String: 1,
            kCFNetworkProxiesHTTPProxy as String: host,
            kCFNetworkProxiesHTTPPort as String: port,
          ]
        }
      #endif
      return URLSession(configuration: configuration)
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
          .filter { $0 != .distantPast }
          .sink { [weak self] _ in
            let filename = "GeoLite2-Country.mmdb"
            let file: String
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
              file = URL.maxmind.appending(path: filename).path(percentEncoded: false)
            } else {
              file = URL.maxmind.appendingPathComponent(filename).path
            }
            self?.delegate?.autoReloadGeoLite2(filePath: file)
          }
          .store(in: &cancellables)

        $enabledHTTPCapabilities
          .sink { [weak self] capabilities in
            self?.delegate?.autoReloadEnabledHTTPCapabilities(capabilities)
          }
          .store(in: &cancellables)

        $outboundMode
          .sink { [weak self] mode in
            self?.delegate?.autoReloadOutboundMode(mode)
          }
          .store(in: &cancellables)

        // Maxmind db auto update.
        Publishers.CombineLatest3(
          $maxminddbDownloadURL,
          $maxminddbLastUpdatedDate,
          $maxminddbKeepUpToDate
        )
        .sink { [weak self] url, date, keepUpToDate in
          guard let self else { return }
          guard keepUpToDate else {
            // Cancel auto update task.
            existingGeoLite2AutoUpdateTask?.cancel()
            return
          }

          let timeIntervalPast = date > .now ? 86400 * 7 : Int64(Date.now.timeIntervalSince(date))
          let initialDelay = TimeAmount.seconds(max(0, 86400 * 7 - timeIntervalPast))
          let delay = TimeAmount.hours(24 * 7)
          existingGeoLite2AutoUpdateTask?.cancel()
          existingGeoLite2AutoUpdateTask =
            eventLoopGroup
            .any()
            .scheduleRepeatedTask(initialDelay: initialDelay, delay: delay) { _ in
              Task.detached {
                try await self.downloadGeoLite2(from: url)
              }
            }
        }
        .store(in: &cancellables)

        // External forwarding rule resources auto update.
        $forwardingRuleResourcesLastUpdatedDate
          .filter { $0 != .distantPast }
          .sink { [weak self] date in
            guard let self else { return }
            let timeIntervalPast = date > .now ? 24 * 3600 : Int64(Date.now.timeIntervalSince(date))
            let initialDelay = TimeAmount.seconds(max(0, 24 * 60 * 60 - timeIntervalPast))
            let delay = TimeAmount.hours(24)
            existingForwardingRulesAutoUpdateTask?.cancel()
            existingForwardingRulesAutoUpdateTask =
              eventLoopGroup
              .any()
              .scheduleRepeatedTask(initialDelay: initialDelay, delay: delay) { _ in
                Task.detached {
                  try await self.downloadExternalForwardingRules()
                }
              }
          }
          .store(in: &cancellables)
      }
    }

    private func downloadGeoLite2(from url: URL) async throws {
      do {
        let profile = try Profile(contentsOf: self.profileURL)
        let session = self._session(
          host: profile.httpListenAddress, port: UInt16(profile.httpListenPort ?? 6152))
        let (url, _) = try await session.download(from: url)

        let filename = "GeoLite2-Country.mmdb"
        let fileURL: URL
        let filePath: String
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
          fileURL = URL.maxmind.appending(path: filename, directoryHint: .notDirectory)
          filePath = fileURL.path(percentEncoded: false)
        } else {
          fileURL = URL.maxmind.appendingPathComponent(filename, isDirectory: false)
          filePath = fileURL.path
        }

        let fs = FileManager.default
        try fs.createDirectory(at: .maxmind, withIntermediateDirectories: true)
        if fs.fileExists(atPath: filePath) {
          try fs.removeItem(at: fileURL)
        }
        try fs.moveItem(at: url, to: fileURL)

        self.maxminddbLastUpdatedDate = .now
      } catch {
        self.logger.error(
          "MaxMind GeoLite2-Country.mmdb update failure with error: \(error)")
      }
    }

    private func downloadExternalForwardingRules() async throws {
      guard let profile = try? Profile(contentsOf: profileURL) else {
        return
      }
      await withTaskGroup(of: Void.self) { g in

        let session = self._session(
          host: profile.httpListenAddress, port: UInt16(profile.httpListenPort ?? 6152))

        if !FileManager.default.fileExists(
          atPath: URL.externalResourceDirectory.path(percentEncoded: false))
        {
          do {
            try FileManager.default.createDirectory(
              at: .externalResourceDirectory, withIntermediateDirectories: true)
          } catch {
            self.logger.error(
              "Create external resource directory failure with error: \(error)")
          }
        }

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

          guard let resourceURL else {
            continue
          }

          g.addTask {
            var srcURL = resourceURL
            do {
              if !resourceURL.isFileURL {
                let (tmpURL, _) = try await session.download(from: srcURL)
                srcURL = tmpURL
              }

              if FileManager.default.fileExists(
                atPath: dstURL.path(percentEncoded: false))
              {
                try FileManager.default.removeItem(at: dstURL)
              }
              try FileManager.default.moveItem(at: srcURL, to: dstURL)
            } catch {
              self.logger.error(
                "External resources \(srcURL) update failure with error: \(error)")
            }
          }
        }
        await g.waitForAll()

        self.forwardingRuleResourcesLastUpdatedDate = .now
      }
    }

    public func shutdownGracefully() async throws {
      lock.withLock {
        for cancellable in cancellables {
          cancellable.cancel()
        }
        cancellables.removeAll()
      }
    }
  }

  extension CapabilityFlags: @retroactive PreferenceRepresentable {}
#endif
