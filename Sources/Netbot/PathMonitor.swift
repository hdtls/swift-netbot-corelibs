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

#if canImport(Network)
  import Darwin
  import Foundation
  import Logging
  import NIOCore
  import NetbotLiteData
  import Network
  import UserNotifications

  #if os(iOS)
    import NetworkExtension
  #else
    import CoreWLAN
  #endif

  #if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    import NIOConcurrencyHelpers
  #else
    import Synchronization
  #endif

  /// A wrap class for `NWPathMonitor` providing default `pathUpdateHandler`.
  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Lockable final public class PathMonitor: Sendable {

    private let pathMonitor: NWPathMonitor

    /// Access the current network path tracked by the monitor
    public var currentPath: NWPath {
      pathMonitor.currentPath
    }

    /// Set a block to be called when the network path changes. pathUpdateHandler will not be called until `start` is called.
    @preconcurrency final public var pathUpdateHandler: (@Sendable (_ newPath: NWPath) -> Void)?

    /// Get queue used for delivering the pathUpdateHandler block.
    /// If the path monitor has not yet been started, the queue will be nil. Once the
    /// path monitor has been started, the queue will be non-nil.
    final public var queue: DispatchQueue? { pathMonitor.queue }

    private var expiredPath: (String, String)

    private let logger = Logger(label: "path-monitor")

    /// Create a network path monitor to monitor overall network state for the
    /// system and to enumerate all interfaces that are available for
    /// general use by applications.
    public init() {
      self.pathMonitor = NWPathMonitor()
      self._pathUpdateHandler = .init(nil)
      self._expiredPath = .init(("", ""))
      self.pathMonitor.pathUpdateHandler = pathUpdateHandler0
    }

    /// Start the path monitor and set a queue on which path updates
    /// will be delivered.
    /// Start should only be called once on a monitor, and multiple calls to start will
    /// be ignored.
    /// Once started, the path monitor must be explicitly cancelled when it is no longer needed.
    public func run() async throws {
      pathMonitor.start(queue: .global())
    }

    /// Cancel the path monitor, after which point no more path updates will
    /// be delivered.
    public func shutdownGracefully() async {
      pathMonitor.cancel()
    }

    private func pathUpdateHandler0(_ path: NWPath) {
      Task.detached {
        self.queue?.async {
          self.pathUpdateHandler?(path)
        }

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
        guard ssid != self.expiredPath.0 || address != self.expiredPath.1 else {
          return
        }
        self.expiredPath = (ssid, address)

        self.logger.info("Network has been changed to \(ssid), New IP address: \(address)")

        let content = UNMutableNotificationContent()
        #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
          content.title = String(
            localized: "Network Changed",
            comment: "Title of network changed notification"
          )
        #else
          content.title = String(
            localized: "Network Changed",
            comment: "Title of network changed notification"
          )
        #endif

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
