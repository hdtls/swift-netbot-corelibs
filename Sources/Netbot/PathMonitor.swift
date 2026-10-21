// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import Logging
import NEAddressProcessing
import NIOCore
import Synchronization
import SynchronizationExtras

#if canImport(Network)
  import Darwin
  import Foundation
  import Network
  import UserNotifications

  #if os(iOS)
    import NetworkExtension
  #elseif os(macOS)
    import CoreWLAN
  #endif
#endif

/// An Path object represents a snapshot of network path state. This state
/// represents the known information about the local interface and routes that may
/// be used to send and receive data. If the network path for a connection changes
/// due to interface characteristics, addresses, or other attributes, a new Path
/// object will be generated. Note that the differences in the path attributes may not
/// be visible through public accessors, and these changes should be treated merely
/// as an indication that something about the network has changed.
@available(SwiftStdlib 6.0, *)
public struct Path: Equatable, CustomDebugStringConvertible, Sendable {

  public var debugDescription: String { "" }

  #if canImport(Network)
    /// An Path status indicates if there is a usable route available upon which to send and receive data.
    public typealias Status = NWPath.Status

    /// An Path unsatisfiedReason may indicate a reason the path is unsatisfied
    public typealias UnsatisfiedReason = NWPath.UnsatisfiedReason

    /// Represents the link quality measurement of the link layer network attachment
    ///
    /// Use this value to tune initial values for algorithms that can scale with the
    /// capabilities of the network. Do not use this value to gate connection attempts or
    /// to override adjustments that would be made based on actual network performance.
    #if compiler(>=6.4)
      @available(anyAppleOS 26.0, *)
    #else
      @available(SwiftStdlib 6.2, *)
    #endif
    public typealias LinkQuality = NWPath.LinkQuality

    /// An Interface object represents an instance of a network interface of a specific
    /// type, such as a Wi-Fi or Cellular interface.
    public typealias Interface = NWInterface
  #else
    /// An Path status indicates if there is a usable route available upon which to send and receive data.
    public enum Status: Hashable, Sendable {

      /// The path has a usable route upon which to send and receive data
      case satisfied

      /// The path does not have a usable route. This may be due to a network interface being down, or due to system policy.
      case unsatisfied

      /// The path does not currently have a usable route, but a connection attempt will trigger network attachment.
      case requiresConnection
    }

    /// An Path unsatisfiedReason may indicate a reason the path is unsatisfied
    public enum UnsatisfiedReason: Hashable, Sendable {

      /// No reason is given
      case notAvailable

      /// The user has disabled cellular
      case cellularDenied

      /// The user has disabled Wi-Fi
      case wifiDenied

      /// The user has disabled local network access
      case localNetworkDenied

      /// A required VPN is not active
      case vpnInactive
    }

    /// Represents the link quality measurement of the link layer network attachment
    ///
    /// Use this value to tune initial values for algorithms that can scale with the
    /// capabilities of the network. Do not use this value to gate connection attempts or
    /// to override adjustments that would be made based on actual network performance.
    public enum LinkQuality: Hashable, Sendable {

      /// No link quality measurement is available
      case unknown

      /// Link quality is minimal
      case minimal

      /// Link quality is moderate
      case moderate

      /// Link quality is good
      case good
    }

    /// An Interface object represents an instance of a network interface of a specific
    /// type, such as a Wi-Fi or Cellular interface.
    public typealias Interface = NIONetworkDevice
  #endif

  public let status: Status

  /// A list of all interfaces currently available to this path
  public let availableInterfaces: [Interface]

  /// Checks if the path uses an NWInterface that is considered to be expensive
  ///
  /// Cellular interfaces are considered expensive. WiFi hotspots from an iOS device are considered expensive. Other
  /// interfaces may appear as expensive in the future.
  public let isExpensive: Bool

  /// Checks if the path uses an NWInterface that is considered to be constrained
  /// by user preference
  public var isConstrained: Bool { _isConstrained }
  private var _isConstrained: Bool

  /// Checks if the path uses an NWInterface that is considered to be constrained
  /// by user preference
  #if compiler(>=6.4)
    @available(anyAppleOS 26.0, *)
  #else
    @available(SwiftStdlib 6.2, *)
  #endif
  public var isUltraConstrained: Bool { _isUltraConstrained }
  private var _isUltraConstrained: Bool

  public let supportsIPv4: Bool

  public let supportsIPv6: Bool

  public let supportsDNS: Bool

  /// A list of IP addresses of routers acting as gateways for the path.
  public var gateways: [Address] { _gateways }
  private var _gateways: [Address] = []

  /// Check the local endpoint set on a path. This will be nil for paths
  /// from an PathMonitor. For paths from an Connection, this will
  /// be set to the local address and port in use by the connection.
  public let localEndpoint: Address?

  /// Check the remote endpoint set on a path. This will be nil for paths
  /// from an PathMonitor. For paths from an Connection, this will
  /// be set to the remote address and port in use by the connection.
  public let remoteEndpoint: Address?

  /// Represents the link quality measurement of the link layer network attachment
  ///
  /// Use this value to tune initial values for algorithms that can scale with the
  /// capabilities of the network. Do not use this value to gate connection attempts or
  /// to override adjustments that would be made based on actual network performance.
  #if compiler(>=6.4)
    @available(anyAppleOS 26.0, *)
  #else
    @available(SwiftStdlib 6.2, *)
  #endif
  public var linkQuality: LinkQuality { _linkQuality as! LinkQuality }
  private var _linkQuality: any Sendable

  #if compiler(>=6.4)
    @available(anyAppleOS 26.0, *)
  #else
    @available(SwiftStdlib 6.2, *)
  #endif
  fileprivate init(
    status: Status, availableInterfaces: [Interface], isExpensive: Bool, isConstrained: Bool,
    isUltraConstrained: Bool, supportsIPv4: Bool, supportsIPv6: Bool, supportsDNS: Bool,
    gateways: [Address], localEndpoint: Address?, remoteEndpoint: Address?, linkQuality: LinkQuality
  ) {
    self.status = status
    self.availableInterfaces = availableInterfaces
    self.isExpensive = isExpensive
    self._isConstrained = isConstrained
    self._isUltraConstrained = isUltraConstrained
    self.supportsIPv4 = supportsIPv4
    self.supportsIPv6 = supportsIPv6
    self.supportsDNS = supportsDNS
    self._gateways = gateways
    self.localEndpoint = localEndpoint
    self.remoteEndpoint = remoteEndpoint
    self._linkQuality = linkQuality
  }

  #if canImport(Network)
    fileprivate init(path: NWPath) {
      _isUltraConstrained = false
      _linkQuality = 0
      #if compiler(>=6.4)
        if #available(anyAppleOS 26.0, *) {
          _isUltraConstrained = path.isUltraConstrained
          _linkQuality = path.linkQuality
        }
      #else
        if #available(SwiftStdlib 6.2, *) {
          _isUltraConstrained = path.isUltraConstrained
          _linkQuality = path.linkQuality
        }
      #endif
      status = path.status
      availableInterfaces = path.availableInterfaces
      isExpensive = path.isExpensive
      _isConstrained = path.isConstrained
      supportsIPv4 = path.supportsIPv4
      supportsIPv6 = path.supportsIPv6
      supportsDNS = path.supportsDNS
      _gateways = path.gateways.compactMap { try? $0.asAddress() }
      localEndpoint = try? path.localEndpoint?.asAddress()
      remoteEndpoint = try? path.remoteEndpoint?.asAddress()
    }
  #endif

  public static func == (lhs: Path, rhs: Path) -> Bool {
    let isEqual =
      lhs.status == rhs.status
      && lhs.isExpensive == rhs.isExpensive
      && lhs.isConstrained == rhs.isConstrained
      && lhs.supportsIPv4 == rhs.supportsIPv4
      && lhs.supportsIPv6 == rhs.supportsIPv6
      && lhs.supportsDNS == rhs.supportsDNS
      && lhs.gateways == rhs.gateways
      && lhs.localEndpoint == rhs.localEndpoint
      && lhs.remoteEndpoint == rhs.remoteEndpoint

    #if compiler(>=6.4)
      if #available(anyAppleOS 26.0, *) {
        return isEqual && lhs.linkQuality == rhs.linkQuality
      } else {
        return isEqual
      }
    #else
      if #available(SwiftStdlib 6.2, *) {
        return isEqual && lhs.linkQuality == rhs.linkQuality
      } else {
        return isEqual
      }
    #endif
  }
}

/// The PathMonitor allows the caller to fetch the current global path (or
/// a path restricted to a specific network interface type). The path for the monitor
/// is an observable property that will be updated upon each network change.
/// Paths generated by a path monitor are not specific to a given endpoint, and
/// will not have the localEndpoint or remoteEndpoint properties set.
/// The paths will watch the state of multiple interfaces, and allows the
/// application to enumerate the available interfaces for use in creating connections
/// or listeners bound to specific interfaces.
@available(SwiftStdlib 6.0, *)
@Lockable final public class PathMonitor: Sendable {

  #if canImport(Network)
    private let pathMonitor: NWPathMonitor
  #endif

  /// Access the current network path tracked by the monitor
  public var currentPath: Path {
    #if canImport(Network)
      return Path(path: pathMonitor.currentPath)
    #else
      return Path(
        status: .requiresConnection, availableInterfaces: [], isExpensive: false,
        isConstrained: false, isUltraConstrained: false, supportsIPv4: true, supportsIPv6: true,
        supportsDNS: true, gateways: [], localEndpoint: nil, remoteEndpoint: nil,
        linkQuality: .unknown
      )
    #endif
  }

  /// Set a block to be called when the network path changes. pathUpdateHandler will not be called until `start` is called.
  final public var pathUpdateHandler: (@Sendable (_ newPath: Path) -> Void)? = nil

  private var expiredPath: (String, String) = ("", "")

  /// Create a network path monitor to monitor overall network state for the
  /// system and to enumerate all interfaces that are available for
  /// general use by applications.
  public init() {
    #if canImport(Network)
      self.pathMonitor = NWPathMonitor()
    #endif
  }

  /// Start the path monitor and set a queue on which path updates
  /// will be delivered.
  /// Start should only be called once on a monitor, and multiple calls to start will
  /// be ignored.
  /// Once started, the path monitor must be explicitly cancelled when it is no longer needed.
  public func run() async throws {
    await withTaskCancellationHandler {
      #if canImport(Network)
        pathMonitor.start(queue: .global())

        for await path in pathMonitor {
          try? await pathUpdateHandler0(Path(path: path))
        }
      #endif
    } onCancel: {
      #if canImport(Network)
        pathMonitor.cancel()
      #endif
    }
  }

  private func pathUpdateHandler0(_ path: Path) async throws {
    self.pathUpdateHandler?(path)

    #if os(iOS)
      let ssid = await withCheckedContinuation { continuation in
        NEHotspotNetwork.fetchCurrent {
          continuation.resume(returning: $0?.ssid)
        }
      }
      let interfaceName = path.availableInterfaces.first?.name
    #elseif os(macOS)
      let ssid = CWWiFiClient.shared().interface()?.ssid()
      let interfaceName = CWWiFiClient.shared().interface()?.interfaceName
    #else
      let ssid = Optional<String>.none
      let interfaceName = path.availableInterfaces.first?.name
    #endif

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

    Logger.current.info("Network has been changed to \(ssid), New IP address: \(address)")

    #if canImport(UserNotifications)
      let content = UNMutableNotificationContent()
      content.title = String(
        localized: "Network Changed",
        comment: "Title of network changed notification"
      )

      content.subtitle = ssid
      content.body = address

      let notification = UNNotificationRequest(
        identifier: content.title,
        content: content,
        trigger: nil
      )
      await UNUserNotificationCenter.default.post(notification)
    #endif
  }
}
