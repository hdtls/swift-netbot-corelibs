//
// See LICENSE.txt for license information
//

#if canImport(Combine)
  import Anlzr
  import Combine
  import Logging
  import MaxMindDB
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

  public protocol AutoReloadDelegate: AnyObject, Sendable {

    func setGeoLite2DB(_ db: MaxMindDB) async throws

    func setOutboundMode(_ outboundMode: OutboundMode) async

    func setEnabledHTTPCapabilities(_ enabledHTTPCapabilities: CapabilityFlags) async

    func setProfile(_ profile: Profile) async throws
  }

  final public class AutoReload: @unchecked Sendable {

    @Preference(Prefs.Name.profileURL, store: .applicationGroup)
    public var profileURL = URL.profile

    @Preference(Prefs.Name.profileLastContentModificationDate, store: .applicationGroup)
    private var profileLastContentModificationDate = Date.now

    @Preference(Prefs.Name.profileAutoreload, store: .applicationGroup)
    public var profileAutoreload = false

    @Preference(Prefs.Name.enableEnhancedMode, store: .applicationGroup)
    public var enableEnhancedMode = false

    @Preference(Prefs.Name.enableSystemProxy, store: .applicationGroup)
    public var enableSystemProxy = false

    @Preference(Prefs.Name.outboundMode, store: .applicationGroup)
    public var outboundMode = OutboundMode.direct

    @Preference(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
    public var enabledHTTPCapabilities = CapabilityFlags()

    @Preference(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
    public var selectionRecords = "{}"

    @Preference(Prefs.Name.maxminddbDownloadURL, store: .applicationGroup)
    public var maxminddbDownloadURL = URL(string: "https://git.io/GeoLite2-Country.mmdb")!

    @Preference(Prefs.Name.maxminddbLastUpdatedDate, store: .applicationGroup)
    public var maxminddbLastUpdatedDate = Date(timeIntervalSinceReferenceDate: 0)

    @Preference(Prefs.Name.maxminddbKeepUpToDate, store: .applicationGroup)
    public var maxminddbKeepUpToDate = true

    @Preference(Prefs.Name.forwardingRuleResourcesLastUpdatedDate, store: .applicationGroup)
    public var forwardingRuleResourcesLastUpdatedDate = Date(timeIntervalSinceReferenceDate: 0)

    private var profileUpdatesTask: AnyCancellable?
    private var outboundModeUpdatesTask: Task<Void, any Error>?
    private var enabledHTTPCapabilitiesUpdatesTask: Task<Void, any Error>?
    private var maxminddbUpdatesTask: AnyCancellable?
    private var existingGeoLite2AutoUpdateTask: RepeatedTask?
    private var forwardingRuleResourcesUpdatesTask: AnyCancellable?
    private var existingForwardingRulesAutoUpdateTask: RepeatedTask?

    private let lock = NIOLock()

    #if canImport(Darwin)
      private let pathMonitor = PathMonitor()
    #endif

    public weak var delegate: (any AutoReloadDelegate)?

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
        wrappedValue: .distantPast,
        Prefs.Name.profileLastContentModificationDate,
        store: store
      )
      self._profileAutoreload = .init(
        wrappedValue: false,
        Prefs.Name.profileAutoreload,
        store: store
      )
      self._enableSystemProxy = .init(
        wrappedValue: false,
        Prefs.Name.enableSystemProxy,
        store: store
      )
      self._enableEnhancedMode = .init(
        wrappedValue: false,
        Prefs.Name.enableEnhancedMode,
        store: store
      )
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
        wrappedValue: .distantPast,
        Prefs.Name.maxminddbLastUpdatedDate,
        store: store
      )
      self._maxminddbKeepUpToDate = .init(
        wrappedValue: false,
        Prefs.Name.maxminddbKeepUpToDate,
        store: store
      )
      self._forwardingRuleResourcesLastUpdatedDate = .init(
        wrappedValue: .distantPast,
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
        let autoreload = $profileLastContentModificationDate.filter { $0 != .distantPast }
          .combineLatest(
            $maxminddbLastUpdatedDate.filter { $0 != .distantPast },
            $forwardingRuleResourcesLastUpdatedDate.filter { $0 != .distantPast }
          )
          // It's a duplicated trigger with `$profileURL` drop it.
          .dropFirst()
          .combineLatest($profileURL, $profileAutoreload)
          // Reload profile only when autoreload is enabled.
          .filter { _, _, autoreload in autoreload }
          .map(\.1)
          .eraseToAnyPublisher()

        profileUpdatesTask =
          $profileURL
          .combineLatest($selectionRecords)
          .map(\.0)
          .merge(with: autoreload)
          .dropFirst()
          .sink { [unowned self] url in
            Task {
              let profile = try Profile(contentsOf: url)
              try await delegate?.setProfile(profile)
            }
          }

        if enabledHTTPCapabilitiesUpdatesTask == nil {
          enabledHTTPCapabilitiesUpdatesTask = Task {
            for await capabilities in $enabledHTTPCapabilities.values {
              try Task.checkCancellation()
              await delegate?.setEnabledHTTPCapabilities(capabilities)
            }
          }
        }

        if outboundModeUpdatesTask == nil {
          outboundModeUpdatesTask = Task {
            for await outboundMode in $outboundMode.values {
              try Task.checkCancellation()
              await delegate?.setOutboundMode(outboundMode)
            }
          }
        }

        if maxminddbUpdatesTask == nil {
          maxminddbUpdatesTask = $maxminddbDownloadURL.combineLatest(
            $maxminddbLastUpdatedDate, $maxminddbKeepUpToDate
          )
          .sink { [weak self] url, date, keepUpToDate in
            guard let self else {
              return
            }

            guard keepUpToDate else {
              // Cancel auto update task.
              existingGeoLite2AutoUpdateTask?.cancel()
              return
            }

            // Previous update task is outdated, we should cancel it.
            existingGeoLite2AutoUpdateTask?.cancel()

            let initialDelay = TimeAmount.seconds(
              max(0, 86400 * 7 - Int64(Date.now.timeIntervalSince(date))))
            let delay = TimeAmount.seconds(86400 * 7)
            existingGeoLite2AutoUpdateTask = eventLoopGroup.any().scheduleRepeatedTask(
              initialDelay: initialDelay, delay: delay
            ) { _ in
              Task.detached {
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
            }
          }
        }

        if forwardingRuleResourcesUpdatesTask == nil {
          forwardingRuleResourcesUpdatesTask = $forwardingRuleResourcesLastUpdatedDate.sink {
            [weak self] date in
            guard let self else {
              return
            }

            existingForwardingRulesAutoUpdateTask?.cancel()

            let seconds: Int64 = 24 * 60 * 60
            let initialDelay = TimeAmount.seconds(
              max(0, seconds - Int64(Date.now.timeIntervalSince(date))))
            let delay = TimeAmount.seconds(seconds)
            existingForwardingRulesAutoUpdateTask = eventLoopGroup.any().scheduleRepeatedTask(
              initialDelay: initialDelay, delay: delay
            ) { _ in
              Task.detached {
                await withTaskGroup(of: Void.self) { g in
                  guard let profile = try? Profile(contentsOf: self.profileURL) else {
                    return
                  }

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
            }
          }
        }
      }

      try await pathMonitor.startMonitoring()
    }

    public func shutdownGracefully() async throws {
      lock.withLock {
        profileUpdatesTask?.cancel()
        profileUpdatesTask = nil

        outboundModeUpdatesTask?.cancel()
        outboundModeUpdatesTask = nil

        enabledHTTPCapabilitiesUpdatesTask?.cancel()
        enabledHTTPCapabilitiesUpdatesTask = nil

        maxminddbUpdatesTask?.cancel()
        maxminddbUpdatesTask = nil

        forwardingRuleResourcesUpdatesTask?.cancel()
        forwardingRuleResourcesUpdatesTask = nil
      }
      await pathMonitor.stopMonitoring()
    }
  }

  extension CapabilityFlags: @retroactive PreferenceRepresentable {}
#endif
