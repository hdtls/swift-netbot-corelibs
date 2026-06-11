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

import Alamofire
import Dispatch
import Logging
import Synchronization
import SynchronizationExtras

#if os(macOS)
  import CoreWLAN
  import SystemConfiguration
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

/// The `AirPort` is a state object of the Wi-Fi subsystem which provides access to all Wi-Fi interfaces.
@available(SwiftStdlib 6.0, *)
#if canImport(Darwin) || swift(>=6.3)
  @Observable
#endif
@MainActor final public class AirPort {

  struct AirPortMonitor: Sendable {

    private let publicIPs: @Sendable () async throws -> Void

    private let start:
      @Sendable (
        _ queue: DispatchQueue,
        _ onResult: @escaping @Sendable (_ result: AirPortPath) -> Void
      ) throws -> Void

    private let stop: @Sendable () throws -> Void

    init(
      publicIPs: @Sendable @escaping () async throws -> Void,
      start:
        @escaping @Sendable (
          _ queue: DispatchQueue,
          _ onResult: @escaping @Sendable (_ result: AirPortPath) -> Void
        ) throws -> Void,
      stop: @escaping @Sendable () throws -> Void
    ) {
      self.publicIPs = publicIPs
      self.start = start
      self.stop = stop
    }

    nonisolated func startListening(
      on queue: DispatchQueue = .main,
      onResult: @escaping @Sendable (AirPortPath) -> Void
    ) throws {
      try start(queue, onResult)
    }

    nonisolated func stopListening() throws {
      try stop()
    }

    nonisolated func requestPublicIPs() async throws {
      try await publicIPs()
    }
  }

  /// Channel width values.
  public enum ChannelWidth: Int, Sendable {
    /// Unknown channel width.
    case unknown

    /// 20MHz channel width.
    case width20MHz

    /// 40MHz channel width.
    case width40MHz

    /// 80MHz channel width.
    case width80MHz

    /// 160MHz channel width.
    case width160MHz
  }

  /// Channel band values.
  public enum ChannelBand: Int, Sendable {
    /// Unknown channel band.
    case unknown

    /// 2.4GHz channel band.
    case band2GHz

    /// 5GHz channel band.
    case band5GHz

    /// 6GHz channel band.
    case band6GHz
  }

  /// The IEEE 802.11 physical layer mode.
  public enum PHYMode: Int, Sendable {
    case none

    /// IEEE 802.11a physical layer mode.
    case mode11a

    /// IEEE 802.11b physical layer mode.
    case mode11b

    /// IEEE 802.11g physical layer mode.
    case mode11g

    /// IEEE 802.11n physical layer mode.
    case mode11n

    /// IEEE 802.11ac physical layer mode.
    case mode11ac

    /// IEEE 802.11ax physical layer mode.
    case mode11ax
  }

  /// Wi-Fi security types.
  public enum Security: Int, Sendable {

    /// Open System authentication.
    case none

    /// WEP security.
    case wep

    /// WPA Personal authentication.
    case wpaPersonal

    /// WPA/WPA2 Personal authentication.
    case wpaPersonalMixed

    /// WPA2 Personal authentication.
    case wpa2Personal

    case personal

    /// Dynamic WEP security.
    case dynamicWEP

    /// WPA Enterprise authentication.
    case wpaEnterprise

    /// WPA/WPA2 Enterprise authentication.
    case wpaEnterpriseMixed

    /// WPA2 Enterprise authentication.
    case wpa2Enterprise

    case enterprise

    /// WPA3 Personal authentication.
    case wpa3Personal

    /// WPA3 Enterprise authentication.
    case wpa3Enterprise

    /// WPA3 Transition (WPA3/WPA2 Personal) authentication.
    case wpa3Transition

    /// OWE security.
    case owe

    /// OWE Transition.
    case oweTransition

    /// Unknown security type.
    case unknown = 9_223_372_036_854_775_807
  }

  struct AirPortPath: Equatable, Hashable, Sendable {
    var name: String = "-"
    var powerOn = false
    var transmitRate: Double = 0
    var mtu: Int32 = 1500
    var mediaSubType: String = "N/A"
    var ssid: String = "N/A"
    var bssid: String = "N/A"
    var countryCode: String = "N/A"
    var rssi: Int = 0
    var noise: Int = 0
    var networkService: NetworkService = .init()
    var publicIPs: [String] = []
    var addressesUpdatedDate: Date = .now
    var hardwareAddress: String = "N/A"
    var activePHYMode: PHYMode = .none
    var channelBand: ChannelBand = .unknown
    var channelWidth: ChannelWidth = .unknown
    var channelNumber: Int = 11
    var channel: String {
      return "\(channelNumber) (\(channelBand.localizedName), \(channelWidth.localizedName))"
    }
    var security: Security = .none
    var transmitPower: Int = 0
  }

  /// Composite network services
  public struct NetworkService: Hashable, Sendable {

    /// An object represent the IPv4 network services.
    public struct IPv4: Hashable, Sendable {

      /// The IPv4 config method for the current connected Wi-Fi client.
      public var configMethod: String = ""

      /// IPv4 router address for the current connected Wi-Fi client..
      public var router: String? = ""

      /// IPv4 addresses for the current connected Wi-Fi client.
      public var addresses: [String] = []

      /// IPv4 subnet masks for the current connected Wi-Fi client.
      public var subnetMasks: [String] = []
    }

    /// An object represent the IPv6 network services.
    public struct IPv6: Hashable, Sendable {

      /// The IPv6 config method for the current connected Wi-Fi client.
      public var configMethod: String = ""

      /// IPv6 router address for the current connected Wi-Fi client..
      public var router: String? = ""

      /// IPv6 addresses for the current connected Wi-Fi client.
      public var addresses: [String] = []

      /// IPv6 flags for the current connected Wi-Fi client.
      public var flags: [String] = []

      /// IPv6 prefix length for the current connected Wi-Fi client.
      public var prefixLength: String = ""
    }

    /// IPv4 network service.
    public var v4: IPv4 = .init()

    /// IPv6 network service.
    public var v6: IPv6 = .init()

    /// DNS servers for the connected Wi-Fi client.
    public var dnsServers: [String] = []
  }

  fileprivate var currentPath = AirPortPath()

  /// Returns a boolean value determine whether the Wi-Fi client is available or not.
  public var isAvailable: Bool {
    interfaceName != "-"
  }

  /// Returns the name of the Wi-Fi interface.
  public var interfaceName: String {
    currentPath.name
  }

  /// Returns a boolean value determine whether the Wi-Fi is power on.
  public var powerOn: Bool {
    currentPath.powerOn
  }

  /// Returns the ransmit rate of the current connected Wi-Fi client..
  public var transmitRate: Double {
    currentPath.transmitRate
  }

  /// Returns the MTU of the current connected Wi-Fi client..
  public var mtu: Int32 {
    currentPath.mtu
  }

  /// Returns the media sub type of the current connected Wi-Fi client..
  public var mediaSubType: String {
    currentPath.mediaSubType
  }

  /// Returns the SSID of the current connected Wi-Fi client..
  public var ssid: String {
    currentPath.ssid
  }

  /// Returns the BSSID of the current connected Wi-Fi client..
  public var bssid: String {
    currentPath.bssid
  }

  /// Returns the country code of the current connected Wi-Fi client..
  public var countryCode: String {
    currentPath.countryCode
  }

  /// Returns the RSSI of the current connected Wi-Fi client..
  public var rssi: Int {
    currentPath.rssi
  }

  /// Returns the noise of the current connected Wi-Fi client..
  public var noise: Int {
    currentPath.noise
  }

  /// Returns the network services of the current connected Wi-Fi client..
  public var networkService: NetworkService {
    currentPath.networkService
  }

  /// Returns the public IPs of the current connected Wi-Fi client..
  public var publicIPs: [String] {
    currentPath.publicIPs
  }

  /// Returns the date which the current connected Wi-Fi's public IPs updated.
  public var addressesUpdatedDate: Date {
    currentPath.addressesUpdatedDate
  }

  /// Returns the hardware address of the current connected Wi-Fi client.
  public var hardwareAddress: String {
    currentPath.hardwareAddress
  }

  /// Returns the active physical layer mode of the current connected Wi-Fi client..
  public var activePHYMode: PHYMode {
    currentPath.activePHYMode
  }

  /// Returns the channel band of the current connected Wi-Fi client..
  public var channelBand: ChannelBand {
    currentPath.channelBand
  }

  /// Returns the channel width of the current connected Wi-Fi client..
  public var channelWidth: ChannelWidth {
    currentPath.channelWidth
  }

  /// Returns the channel number of the current connected Wi-Fi client..
  public var channelNumber: Int {
    currentPath.channelNumber
  }

  /// Returns the formatted channel of the current connected Wi-Fi client.
  public var channel: String {
    currentPath.channel
  }

  /// Returns the security of the current connected Wi-Fi client..
  public var security: Security {
    currentPath.security
  }

  /// Returns the transmit power of the current connected Wi-Fi client..
  public var transmitPower: Int {
    currentPath.transmitPower
  }

  private let logger = Logger(label: "AirPort")

  nonisolated private let monitor: AirPortMonitor

  /// Create a new instance of `AirPort`.
  nonisolated public convenience init() {
    #if os(macOS)
      self.init(monitor: .init(monitor: CWAirPortMonitor()))
    #else
      self.init(
        monitor: .init(
          publicIPs: {

          },
          start: { _, _ in

          },
          stop: {

          }))
    #endif
  }

  nonisolated init(monitor: AirPortMonitor) {
    self.monitor = monitor
  }

  deinit {
    stopListening()
  }

  #if swift(>=6.2)
    /// Request public IPs for current connected Wi-Fi.
    @concurrent public func requestPublicIPs() async throws {
      try await monitor.requestPublicIPs()
    }
  #else
    /// Request public IPs for current connected Wi-Fi.
    nonisolated public func requestPublicIPs() async throws {
      try await monitor.requestPublicIPs()
    }
  #endif

  /// Start listening Wi-Fi changes.
  nonisolated public func startListening() {
    do {
      try monitor.startListening { device in
        Task { @MainActor in
          self.currentPath = device
        }
      }
    } catch {
      logger.error("\(error)")
    }
  }

  /// Stop listening Wi-Fi changes.
  nonisolated public func stopListening() {
    do {
      try monitor.stopListening()
    } catch {
      logger.error("\(error)")
    }
  }
}

#if os(macOS)
  @available(SwiftStdlib 6.0, *)
  extension AirPort {
    @Lockable final fileprivate class CWAirPortMonitor: Sendable {

      private var currentPath: AirPortPath = .init()

      fileprivate nonisolated var client: CWWiFiClient { CWWiFiClient.shared() }

      private var onResult: (@Sendable (AirPortPath) -> Void)? = nil
      private var queue: DispatchQueue = .main

      nonisolated func startListening(
        on queue: DispatchQueue = .main,
        onResult: @escaping @Sendable (AirPortPath) -> Void
      ) throws {
        self.queue = queue
        self.onResult = onResult
        try client.startMonitoringEvent(with: .ssidDidChange)
        try client.startMonitoringEvent(with: .bssidDidChange)
        try client.startMonitoringEvent(with: .countryCodeDidChange)
        try client.startMonitoringEvent(with: .linkQualityDidChange)

        update()
      }

      nonisolated func stopListening() throws {
        self.onResult = nil
        try client.stopMonitoringAllEvents()
      }

      nonisolated private func update() {
        Task {
          await withTaskGroup { g in
            g.addTask {
              await self.requestAirPortInfo()
            }
            g.addTask {
              await self.requestPublicIPs()
            }
            await g.waitForAll()
          }

          queue.async { [weak self] in
            guard let self else { return }
            onResult?(currentPath)
          }
        }
      }

      #if swift(>=6.2)
        @concurrent private func requestAirPortInfo() async {
          await _requestAirPortInfo()
        }

        @concurrent func requestPublicIPs() async {
          await _requestPublicIPs()
        }
      #else
        nonisolated private func requestAirPortInfo() async {
          await _requestAirPortInfo()
        }

        nonisolated func requestPublicIPs() async {
          await _requestPublicIPs()
        }
      #endif

      nonisolated private func _requestAirPortInfo() async {
        if let interface = CWWiFiClient.shared().interface() {
          $currentPath.withLock { currentPath in
            currentPath.name = interface.interfaceName ?? "N/A"
            currentPath.powerOn = interface.powerOn()
            currentPath.activePHYMode =
              .init(
                rawValue: interface.activePHYMode().rawValue
              ) ?? .none
            currentPath.ssid = interface.ssid() ?? "N/A"
            currentPath.bssid = interface.bssid() ?? "N/A"
            currentPath.rssi = interface.rssiValue()
            currentPath.noise = interface.noiseMeasurement()
            currentPath.security = .init(rawValue: interface.security().rawValue) ?? .none
            currentPath.transmitRate = interface.transmitRate()
            currentPath.countryCode = interface.countryCode() ?? "N/A"
            currentPath.transmitPower = interface.transmitPower()
            currentPath.hardwareAddress = interface.hardwareAddress() ?? "N/A"
            currentPath.channelNumber = interface.wlanChannel()?.channelNumber ?? 11
            currentPath.channelBand =
              .init(
                rawValue: (interface.wlanChannel()?.channelBand ?? .bandUnknown).rawValue
              ) ?? .unknown
            currentPath.channelWidth =
              .init(rawValue: (interface.wlanChannel()?.channelWidth ?? .widthUnknown).rawValue)
              ?? .unknown
          }
        }

        let processName = ProcessInfo.processInfo.processName
        guard let pref = SCPreferencesCreate(nil, processName as CFString, nil) else {
          return
        }

        var services = SCNetworkServiceCopyAll(pref) as? [SCNetworkService] ?? []
        services = services.filter {
          guard let interface = SCNetworkServiceGetInterface($0) else {
            return false
          }
          guard SCNetworkInterfaceGetBSDName(interface) as? String == currentPath.name else {
            return false
          }
          return true
        }
        guard let service = services.first, let interface = SCNetworkServiceGetInterface(service)
        else {
          return
        }

        var mtu: Int32 = 1500
        SCNetworkInterfaceCopyMTU(interface, &mtu, nil, nil)
        $currentPath.withLock { $0.mtu = mtu }

        var mediaSubType = "N/A"
        var available: Unmanaged<CFArray>?
        let success = SCNetworkInterfaceCopyMediaOptions(interface, nil, nil, &available, false)
        if success, let available = available?.takeRetainedValue() {
          let copied = SCNetworkInterfaceCopyMediaSubTypes(available) as NSArray?
          mediaSubType = copied?.firstObject as? String ?? "N/A"
          $currentPath.withLock { $0.mediaSubType = mediaSubType }
        }

        let store = SCDynamicStoreCreate(nil, processName as CFString, nil, nil)
        guard let store, let id = SCNetworkServiceGetServiceID(service) else {
          $currentPath.withLock { currentPath in
            currentPath.mtu = mtu
            currentPath.mediaSubType = mediaSubType
          }
          return
        }

        // Copy DNS servers from dynamic store.
        var key = SCDynamicStoreKeyCreateNetworkServiceEntity(
          nil,
          kSCDynamicStoreDomainState,
          id,
          kSCEntNetDNS
        )
        if let propertyList = SCDynamicStoreCopyValue(store, key) {
          if let serverAddresses = propertyList.object(forKey: kSCPropNetDNSServerAddresses)
            as? [String]
          {
            $currentPath.withLock {
              $0.networkService.dnsServers = serverAddresses
            }
          }
        }

        // Copy IPv4 info from dynamic store.
        key = SCDynamicStoreKeyCreateNetworkServiceEntity(
          nil,
          kSCDynamicStoreDomainState,
          id,
          kSCEntNetIPv4
        )
        if let propertyList = SCDynamicStoreCopyValue(store, key) {
          $currentPath.withLock {
            $0.networkService.v4.router = propertyList[kSCPropNetIPv4Router] as? String ?? ""
            $0.networkService.v4.addresses =
              propertyList[kSCPropNetIPv4Addresses] as? [String] ?? []
            $0.networkService.v4.subnetMasks =
              propertyList[kSCPropNetIPv4SubnetMasks] as? [String] ?? []
          }
        }

        // Copy IPv4 config method from dynamic store.
        key = SCDynamicStoreKeyCreateNetworkServiceEntity(
          nil,
          kSCDynamicStoreDomainSetup,
          id,
          kSCEntNetIPv4
        )
        if let propertyList = SCDynamicStoreCopyValue(store, key) {
          $currentPath.withLock {
            $0.networkService.v4.configMethod =
              propertyList[kSCPropNetIPv4ConfigMethod] as? String ?? ""
          }
        }

        // Copy IPv6 info from dynamic store.
        key = SCDynamicStoreKeyCreateNetworkServiceEntity(
          nil,
          kSCDynamicStoreDomainState,
          id,
          kSCEntNetIPv6
        )
        if let propertyList = SCDynamicStoreCopyValue(store, key) {
          $currentPath.withLock {
            $0.networkService.v6.router = propertyList[kSCPropNetIPv6Router] as? String ?? ""
            $0.networkService.v6.addresses =
              propertyList[kSCPropNetIPv6Addresses] as? [String] ?? []
            $0.networkService.v6.flags = propertyList[kSCPropNetIPv6Flags] as? [String] ?? []
            $0.networkService.v6.prefixLength =
              propertyList[kSCPropNetIPv6PrefixLength] as? String ?? ""
          }
        }

        // Copy IPv6 config method from dynamic store.
        key = SCDynamicStoreKeyCreateNetworkServiceEntity(
          nil,
          kSCDynamicStoreDomainSetup,
          id,
          kSCEntNetIPv6
        )
        if let propertyList = SCDynamicStoreCopyValue(store, key) {
          $currentPath.withLock {
            $0.networkService.v6.configMethod =
              propertyList[kSCPropNetIPv6ConfigMethod] as? String ?? ""
          }
        }
      }

      nonisolated private func _requestPublicIPs() async {
        let configuration = URLSessionConfiguration.default
        configuration.proxyConfigurations = []
        configuration.connectionProxyDictionary = [:]

        let session = Alamofire.Session(configuration: configuration)
        let addresses = try? await session.request("https://icanhazip.com").serializingString()
          .value
          .components(separatedBy: .whitespacesAndNewlines)

        $currentPath.withLock { currentPath in
          currentPath.publicIPs = addresses ?? []
          currentPath.addressesUpdatedDate = .now
        }

        queue.async { [weak self] in
          guard let self else { return }
          onResult?(currentPath)
        }
      }
    }
  }

  @available(SwiftStdlib 6.0, *)
  extension AirPort.CWAirPortMonitor {

    func clientConnectionInterrupted() {
      update()
    }

    func clientConnectionInvalidated() {
      update()
    }

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
      guard currentPath.name == interfaceName else {
        return
      }
      let ssid = client.interface()?.ssid()
      currentPath.ssid = ssid ?? "N/A"

      queue.async { [weak self] in
        guard let self else { return }
        onResult?(currentPath)
      }
    }

    func bssidDidChangeForWiFiInterface(withName interfaceName: String) {
      guard currentPath.name == interfaceName else {
        return
      }
      let bssid = client.interface()?.bssid()
      currentPath.bssid = bssid ?? "N/A"

      queue.async { [weak self] in
        guard let self else { return }
        onResult?(currentPath)
      }
    }

    func countryCodeDidChangeForWiFiInterface(withName interfaceName: String) {
      guard currentPath.name == interfaceName else {
        return
      }
      let countryCode = client.interface()?.countryCode()
      currentPath.countryCode = countryCode ?? "N/A"

      queue.async { [weak self] in
        guard let self else { return }
        onResult?(currentPath)
      }
    }

    func linkQualityDidChangeForWiFiInterface(
      withName interfaceName: String,
      rssi: Int,
      transmitRate: Double
    ) {
      guard currentPath.name == interfaceName else {
        return
      }
      let rssi = client.interface()?.rssiValue()
      let transmitRate = client.interface()?.transmitRate()
      currentPath.rssi = rssi ?? 0
      currentPath.transmitRate = transmitRate ?? 0

      queue.async { [weak self] in
        guard let self else { return }
        onResult?(currentPath)
      }
    }
  }

  #if swift(>=6.2)
    @available(SwiftStdlib 6.0, *)
    extension AirPort.CWAirPortMonitor: nonisolated CWEventDelegate {
    }
  #else
    @available(SwiftStdlib 6.0, *)
    extension AirPort.CWAirPortMonitor: @preconcurrency CWEventDelegate {
    }
  #endif

  @available(SwiftStdlib 6.0, *)
  extension AirPort.AirPortMonitor {

    fileprivate init(monitor: AirPort.CWAirPortMonitor) {
      publicIPs = monitor.requestPublicIPs
      start = monitor.startListening
      stop = monitor.stopListening
    }
  }
#endif

@available(SwiftStdlib 6.0, *)
extension AirPort.ChannelWidth {

  /// Returns localized name of the channel width.
  public var localizedName: String {
    switch self {
    case .unknown:
      return "Unknown"
    case .width20MHz:
      return "20MHz"
    case .width40MHz:
      return "40MHz"
    case .width80MHz:
      return "80MHz"
    case .width160MHz:
      return "160MHz"
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension AirPort.ChannelBand {

  /// Returns localized name of the channel band.
  public var localizedName: String {
    switch self {
    case .unknown:
      return "Unknown"
    case .band2GHz:
      return "2.4GHz"
    case .band5GHz:
      return "5GHz"
    case .band6GHz:
      return "6GHz"
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension AirPort.PHYMode {

  /// Returns localized name of the physical layer mode.
  public var localizedName: String {
    switch self {
    case .none:
      return "none"
    case .mode11a:
      return "802.11a"
    case .mode11b:
      return "802.11b"
    case .mode11g:
      return "802.11g"
    case .mode11n:
      return "802.11n"
    case .mode11ac:
      return "802.11ac"
    case .mode11ax:
      return "802.11ax"
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension AirPort.Security {

  /// Returns localized name of the security.
  public var localizedName: String {
    switch self {
    case .none:
      return "none"
    case .wep:
      return "WEP"
    case .wpaPersonal:
      return "WPA Personal"
    case .wpaPersonalMixed:
      return "WPA Personal Mixed"
    case .wpa2Personal:
      return "WPA2 Personal"
    case .personal:
      return "Personal"
    case .dynamicWEP:
      return "Dynamic WEP"
    case .wpaEnterprise:
      return "WPA Enterprise"
    case .wpaEnterpriseMixed:
      return "WPA Enterprise Mixed"
    case .wpa2Enterprise:
      return "WPA2 Enterprise"
    case .enterprise:
      return "Enterprise"
    case .wpa3Personal:
      return "WPA3 Personal"
    case .wpa3Enterprise:
      return "WPA3 Enterprise"
    case .wpa3Transition:
      return "WPA3 Transition"
    case .owe:
      return "OWE"
    case .oweTransition:
      return "OWE Transition"
    case .unknown:
      return "unknown"
    }
  }
}
