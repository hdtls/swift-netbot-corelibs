//
// See LICENSE.txt for license information
//

@_exported public import Anlzr
@_exported public import MaxMindDB
private import NIOConcurrencyHelpers
private import NIOCore
@_exported public import Preference
@_exported public import _ResourceProcessing

#if canImport(FoundationEssentials)
  public import FoundationEssentials
  private import FoundationNetworking
#else
  public import Foundation
#endif

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

  #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
    #if os(macOS)
      @Preference(Prefs.Name.enableEnhancedMode, store: .applicationGroup)
      public var enableEnhancedMode = false
    #else
      @Preference(Prefs.Name.enableEnhancedMode, store: .applicationGroup)
      public var enableEnhancedMode = true
    #endif
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

  private var networkSettingsUpdatesTask: AnyCancellable?
  private var outboundModeUpdatesTask: Task<Void, any Error>?
  private var enabledHTTPCapabilitiesUpdatesTask: Task<Void, any Error>?
  private var selectionRecordUpdatesTask: Task<Void, any Error>?
  private var maxminddbUpdatesTask: AnyCancellable?
  private var existingGeoLite2AutoUpdateTask: RepeatedTask?

  private let lock = NIOLock()

  #if canImport(Darwin)
    private let pathMonitor = PathMonitor()
  #endif

  public weak var delegate: (any EventMonitorDelegate)?

  public var cancellable: AnyCancellable?

  public func startListening() async throws {
    lock.lock()

    #if canImport(Darwin)
      if networkSettingsUpdatesTask == nil {
        #if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
          let publisher = $enableEnhancedMode.eraseToAnyPublisher()
        #else
          let publisher = Just(false).eraseToAnyPublisher()
        #endif
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

        cancellable = $profileLastContentModificationDate.sink {
          AnalyzerBot.shared.logger.trace("\($0)")
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

        let eventLoop = MultiThreadedEventLoopGroup.singleton.any()

        let initialDelay = TimeAmount.seconds(min(0, 86400 * 7 - Int64(date.timeIntervalSinceNow)))
        let delay = TimeAmount.seconds(86400 * 7)
        existingGeoLite2AutoUpdateTask = eventLoop.scheduleRepeatedAsyncTask(
          initialDelay: initialDelay, delay: delay
        ) { _ in
          eventLoop.makeFutureWithTask {
            let (url, _) = try await URLSession.shared.download(from: url)
            let filename = "GeoLite2-Country.mmdb"
            let file = URL.maxmind.appending(path: filename, directoryHint: .notDirectory)
            if FileManager.default.fileExists(atPath: file.path(percentEncoded: false)) {
              try FileManager.default.removeItem(at: file)
            }
            try FileManager.default.moveItem(at: url, to: file)

            let db = try MaxMindDB(file: file.path(percentEncoded: false), mode: .mmap)
            self.delegate?.eventMonitor(self, willChangeMaxMindDB: db)
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

  public init() {
  }
}

extension CapabilityFlags: @retroactive PreferenceRepresentable {}
