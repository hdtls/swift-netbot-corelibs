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

  /// Create a new instance of `AirPort`.
  nonisolated public init() {
  }

  /// Request air port info for current connected Wi-Fi.
  @concurrent public func requestAirPortInfo() async throws {
    #if os(macOS)
      if let interface = CWWiFiClient.shared().interface() {
        let name = interface.interfaceName ?? "N/A"
        let powerOn = interface.powerOn()
        let activePHYMode = PHYMode(rawValue: interface.activePHYMode().rawValue) ?? .none
        let ssid = interface.ssid() ?? "N/A"
        let bssid = interface.bssid() ?? "N/A"
        let rssi = interface.rssiValue()
        let noise = interface.noiseMeasurement()
        let security = Security(rawValue: interface.security().rawValue) ?? .none
        let transmitRate = interface.transmitRate()
        let countryCode = interface.countryCode() ?? "N/A"
        let transmitPower = interface.transmitPower()
        let hardwareAddress = interface.hardwareAddress() ?? "N/A"
        let channelNumber = interface.wlanChannel()?.channelNumber ?? 11
        let channelBand =
          ChannelBand(
            rawValue: (interface.wlanChannel()?.channelBand ?? .bandUnknown).rawValue
          ) ?? .unknown
        let channelWidth =
          ChannelWidth(rawValue: (interface.wlanChannel()?.channelWidth ?? .widthUnknown).rawValue)
          ?? .unknown

        await MainActor.run {
          currentPath.name = name
          currentPath.powerOn = powerOn
          currentPath.activePHYMode = activePHYMode
          currentPath.ssid = ssid
          currentPath.bssid = bssid
          currentPath.rssi = rssi
          currentPath.noise = noise
          currentPath.security = security
          currentPath.transmitRate = transmitRate
          currentPath.countryCode = countryCode
          currentPath.transmitPower = transmitPower
          currentPath.hardwareAddress = hardwareAddress
          currentPath.channelNumber = channelNumber
          currentPath.channelBand = channelBand
          currentPath.channelWidth = channelWidth
        }
      }

      let interfaceName = await currentPath.name
      let processName = ProcessInfo.processInfo.processName
      guard let pref = SCPreferencesCreate(nil, processName as CFString, nil) else {
        return
      }

      var services = SCNetworkServiceCopyAll(pref) as? [SCNetworkService] ?? []
      services = services.filter {
        guard let interface = SCNetworkServiceGetInterface($0) else {
          return false
        }
        guard SCNetworkInterfaceGetBSDName(interface) as? String == interfaceName else {
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
      await MainActor.run { currentPath.mtu = mtu }

      var mediaSubType = "N/A"
      var available: Unmanaged<CFArray>?
      let success = SCNetworkInterfaceCopyMediaOptions(interface, nil, nil, &available, false)
      if success, let available = available?.takeRetainedValue() {
        let copied = SCNetworkInterfaceCopyMediaSubTypes(available) as NSArray?
        mediaSubType = copied?.firstObject as? String ?? "N/A"
        await MainActor.run { currentPath.mediaSubType = mediaSubType }
      }

      let store = SCDynamicStoreCreate(nil, processName as CFString, nil, nil)
      guard let store, let id = SCNetworkServiceGetServiceID(service) else {
        await MainActor.run {
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
          await MainActor.run {
            currentPath.networkService.dnsServers = serverAddresses
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
        let router = propertyList[kSCPropNetIPv4Router] as? String ?? ""
        let addresses = propertyList[kSCPropNetIPv4Addresses] as? [String] ?? []
        let subnetMasks = propertyList[kSCPropNetIPv4SubnetMasks] as? [String] ?? []
        await MainActor.run {
          currentPath.networkService.v4.router = router
          currentPath.networkService.v4.addresses = addresses
          currentPath.networkService.v4.subnetMasks = subnetMasks
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
        let configMethod = propertyList[kSCPropNetIPv4ConfigMethod] as? String ?? ""
        await MainActor.run {
          currentPath.networkService.v4.configMethod = configMethod
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
        let router = propertyList[kSCPropNetIPv6Router] as? String ?? ""
        let addresses = propertyList[kSCPropNetIPv6Addresses] as? [String] ?? []
        let flags = propertyList[kSCPropNetIPv6Flags] as? [String] ?? []
        let prefixLength = propertyList[kSCPropNetIPv6PrefixLength] as? String ?? ""
        await MainActor.run {
          currentPath.networkService.v6.router = router
          currentPath.networkService.v6.addresses = addresses
          currentPath.networkService.v6.flags = flags
          currentPath.networkService.v6.prefixLength = prefixLength
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
        let configMethod = propertyList[kSCPropNetIPv6ConfigMethod] as? String ?? ""
        await MainActor.run {
          currentPath.networkService.v6.configMethod = configMethod
        }
      }
    #endif
  }

  /// Request public IPs for current connected Wi-Fi.
  @concurrent public func requestPublicIPs() async throws {
    #if os(macOS)
      let configuration = URLSessionConfiguration.default
      configuration.proxyConfigurations = []
      configuration.connectionProxyDictionary = [:]

      let session = Alamofire.Session(configuration: configuration)
      let addresses = try? await session.request("https://icanhazip.com").serializingString()
        .value
        .components(separatedBy: .whitespacesAndNewlines)

      await MainActor.run {
        currentPath.publicIPs = addresses ?? []
        currentPath.addressesUpdatedDate = .now
      }
    #endif
  }
}

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
