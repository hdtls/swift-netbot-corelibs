//
// See LICENSE.txt for license information
//

import Anlzr
import Logging
import MaxMindDB
import NIOConcurrencyHelpers
import NIOCore
import Preference
import _PersistentStore
import _ResourceProcessing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Network)
  import Network
  import NIOTransportServices
#else
  import FoundationNetworking
  import NIOPosix
#endif

#if canImport(Darwin)
  public protocol EventMonitorDelegate: AnyObject, Sendable {

    func eventMonitor(
      _ eventMonitor: EventMonitor, willChangeProfile newProfile: Profile, packetProcessing: Bool)

    func eventMonitor(
      _ eventMonitor: EventMonitor, willChangeHTTPCapabilities newCapabilities: CapabilityFlags)

    func eventMonitor(
      _ eventMonitor: EventMonitor, willChangeOutboundMode newOutboundMode: OutboundMode)

    func eventMonitor(_ eventMonitor: EventMonitor, willChangeMaxMindDB newMaxMindDB: MaxMindDB)

    func eventMonitor(
      _ eventMonitor: EventMonitor,
      willChangeForwardProtocol newForwardProtocol: any ForwardProtocolConvertible)

    func eventMonitor(
      _ eventMonitor: EventMonitor,
      willChangeForwardingRules newForwardingRules: [any ForwardingRuleConvertible]
    )
  }

  final public class EventMonitor: @unchecked Sendable {

    @Preference(Prefs.Name.profileURL, store: .applicationGroup)
    public var profileURL = URL.profile

    @Preference(Prefs.Name.profileLastContentModificationDate, store: .applicationGroup)
    private var profileLastContentModificationDate = Date.now

    #if os(macOS)
      @Preference(Prefs.Name.enableEnhancedMode, store: .applicationGroup)
      public var enableEnhancedMode = false
    #else
      @Preference(Prefs.Name.enableEnhancedMode, store: .applicationGroup)
      public var enableEnhancedMode = true
    #endif

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

    private var networkSettingsUpdatesTask: AnyCancellable?
    private var outboundModeUpdatesTask: Task<Void, any Error>?
    private var enabledHTTPCapabilitiesUpdatesTask: Task<Void, any Error>?
    private var selectionRecordUpdatesTask: Task<Void, any Error>?
    private var maxminddbUpdatesTask: AnyCancellable?
    private var existingGeoLite2AutoUpdateTask: RepeatedTask?
    private var forwardingRuleResourcesUpdatesTask: AnyCancellable?
    private var existingForwardingRulesAutoUpdateTask: RepeatedTask?

    private let lock = NIOLock()

    #if canImport(Darwin)
      private let pathMonitor = PathMonitor()
    #endif

    public weak var delegate: (any EventMonitorDelegate)?

    private let logger: Logger
    private let eventLoopGroup: any EventLoopGroup

    public init(group: any EventLoopGroup, logger: Logger) {
      self.eventLoopGroup = group
      self.logger = logger
    }

    private func _session(host: String, port: UInt16) -> URLSession {
      let configuration = URLSessionConfiguration.default
      #if canImport(Darwin)
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

    public func startListening() async throws {
      lock.lock()

      #if canImport(Darwin)
        if networkSettingsUpdatesTask == nil {
          let publisher = $enableEnhancedMode.eraseToAnyPublisher()
          networkSettingsUpdatesTask = $profileURL.combineLatest(
            $profileLastContentModificationDate,
            publisher
          )
          .sink { [unowned self] url, _, packetProcessing in
            Task {
              let profile = try Profile(contentsOf: url)
              delegate?.eventMonitor(
                self, willChangeProfile: profile, packetProcessing: packetProcessing
              )
            }
          }
        }
      #endif

      if enabledHTTPCapabilitiesUpdatesTask == nil {
        enabledHTTPCapabilitiesUpdatesTask = Task {
          for await capabilities in $enabledHTTPCapabilities.values {
            try Task.checkCancellation()
            delegate?.eventMonitor(self, willChangeHTTPCapabilities: capabilities)
          }
        }
      }

      if outboundModeUpdatesTask == nil {
        outboundModeUpdatesTask = Task {
          for await outboundMode in $outboundMode.values {
            try Task.checkCancellation()
            delegate?.eventMonitor(self, willChangeOutboundMode: outboundMode)
          }
        }
      }

      if selectionRecordUpdatesTask == nil {
        selectionRecordUpdatesTask = Task {
          for await _ in $selectionRecords.values {
            try Task.checkCancellation()
            let profile = try Profile(contentsOf: profileURL)
            delegate?.eventMonitor(self, willChangeForwardProtocol: profile.asForwardProtocol())
            delegate?.eventMonitor(self, willChangeForwardingRules: profile.asForwardingRules())
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

                let db = try MaxMindDB(file: filePath, mode: .mmap)
                self.maxminddbLastUpdatedDate = .now
                self.delegate?.eventMonitor(self, willChangeMaxMindDB: db)
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

                      if FileManager.default.fileExists(atPath: dstURL.path(percentEncoded: false))
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
                self.delegate?.eventMonitor(
                  self, willChangeForwardingRules: profile.asForwardingRules())
              }
            }
          }
        }
      }

      #if canImport(Darwin)
        try await pathMonitor.startMonitoring()
      #endif
      lock.unlock()
    }

    public func stopListening() async {
      lock.lock()

      networkSettingsUpdatesTask?.cancel()
      networkSettingsUpdatesTask = nil

      outboundModeUpdatesTask?.cancel()
      outboundModeUpdatesTask = nil

      enabledHTTPCapabilitiesUpdatesTask?.cancel()
      enabledHTTPCapabilitiesUpdatesTask = nil

      selectionRecordUpdatesTask?.cancel()
      selectionRecordUpdatesTask = nil

      maxminddbUpdatesTask?.cancel()
      maxminddbUpdatesTask = nil

      #if canImport(Darwin)
        await pathMonitor.stopMonitoring()
      #endif

      lock.unlock()
    }
  }
#endif

extension CapabilityFlags: @retroactive PreferenceRepresentable {}
