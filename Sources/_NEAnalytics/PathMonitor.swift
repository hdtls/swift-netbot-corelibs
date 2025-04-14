//
// See LICENSE.txt for license information
//

#if canImport(Network)
  import Darwin
  import Logging
  import Network
  import NIOCore
  import NIOConcurrencyHelpers
  import UserNotifications

  #if os(iOS)
    import NetworkExtension
  #else
    import CoreWLAN
  #endif

  /// A wrap class for `NWPathMonitor` providing default `pathUpdateHandler`.
  final public class PathMonitor: Sendable {

    private let pathMonitor: NWPathMonitor

    /// Access the current network path tracked by the monitor
    public var currentPath: NWPath {
      pathMonitor.currentPath
    }

    /// Set a block to be called when the network path changes. pathUpdateHandler will not be called until `start` is called.
    @preconcurrency final public var pathUpdateHandler: (@Sendable (_ newPath: NWPath) -> Void)? {
      get {
        pathMonitor.pathUpdateHandler
      }
      set {
        pathMonitor.pathUpdateHandler = newValue
      }
    }

    /// Get queue used for delivering the pathUpdateHandler block.
    /// If the path monitor has not yet been started, the queue will be nil. Once the
    /// path monitor has been started, the queue will be non-nil.
    final public var queue: DispatchQueue? { pathMonitor.queue }

    private let expiredPath: NIOLockedValueBox<(String, String)>

    private var logger: Logger {
      bot.logger
    }

    private let bot = AnalyzerBot.shared

    /// Create a network path monitor to monitor overall network state for the
    /// system and to enumerate all interfaces that are available for
    /// general use by applications.
    public init() {
      self.pathMonitor = NWPathMonitor()
      self.expiredPath = NIOLockedValueBox<(String, String)>(("", ""))
      pathMonitor.pathUpdateHandler = pathUpdateHandler
    }

    /// Start the path monitor and set a queue on which path updates
    /// will be delivered.
    /// Start should only be called once on a monitor, and multiple calls to start will
    /// be ignored.
    /// Once started, the path monitor must be explicitly cancelled when it is no longer needed.
    public func startMonitoring() async throws {
      pathMonitor.start(queue: .global(qos: .background))
    }

    /// Cancel the path monitor, after which point no more path updates will
    /// be delivered.
    public func stopMonitoring() async {
      pathMonitor.cancel()
    }

    private func pathUpdateHandler(_ path: NWPath) {
      Task.detached {
        #if os(macOS)
          let ssid = CWWiFiClient.shared().interface()?.ssid()
        #else
          let ssid = await withCheckedContinuation { continuation in
            NEHotspotNetwork.fetchCurrent {
              continuation.resume(returning: $0?.ssid)
            }
          }
        #endif
        let interfaceName = path.availableInterfaces.first?.name
        let addresses: [String] = try System.enumerateDevices().compactMap {
          guard $0.name == interfaceName else {
            return nil
          }
          guard case .v4 = $0.address else {
            return nil
          }
          return $0.address?.ipAddress
        }

        guard let ssid, let address = addresses.first else {
          return
        }
        let expiredPath = self.expiredPath.withLockedValue { $0 }
        guard ssid != expiredPath.0 || address != expiredPath.1 else {
          return
        }
        self.expiredPath.withLockedValue { $0 = (ssid, address) }

        self.logger.info("Network has been changed to \(ssid), New IP address: \(address)")

        let content = UNMutableNotificationContent()
        content.title = String(
          localized: "Network Changed",
          comment: "Network changed notification title"
        )
        content.subtitle = ssid
        content.body = address

        let notification = UNNotificationRequest(
          identifier: content.title,
          content: content,
          trigger: nil
        )
        await UNUserNotificationCenter.default.post(notification)
      }
    }
  }
#endif
