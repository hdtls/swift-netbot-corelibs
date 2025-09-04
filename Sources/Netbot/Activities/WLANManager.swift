//
// See LICENSE.txt for license information
//

#if os(macOS)
  import CoreWLAN
  import Foundation
  import Observation
  import Logging
  import SystemConfiguration
  import Network

  private let notApplicable = "N/A"

  @available(SwiftStdlib 5.9, *)
  @MainActor @Observable final public class WLANManager {
    fileprivate struct NetworkDevice: Equatable, Hashable, Sendable {
      var name: String = "-"
      var powerOn = true
      var transmitRate: Double = 0
      var mtu: Int32 = 1500
      var mediaSubType: String = notApplicable
      var ssid: String = notApplicable
      var bssid: String = notApplicable
      var countryCode: String = notApplicable
      var rssi: Int = 0
      var noise: Int = 0
      var networkService: NetworkService = .init()
      var externalIPAddresses: [String] = []
      var addressesUpdatedDate: Date = .now
      var hardwareAddress: String = notApplicable
      var activePHYMode: CWPHYMode = .modeNone
      var channelBand: CWChannelBand = .bandUnknown
      var channelWidth: CWChannelWidth = .widthUnknown
      var channelNumber: Int = 11
      var channel: String {
        return "\(channelNumber) (\(channelBand.localizedName), \(channelWidth.localizedName))"
      }
      var security: CWSecurity = .unknown
      var transmitPower: Int = 0
    }

    public struct NetworkService: Hashable, Sendable {
      public struct IPv4: Hashable, Sendable {
        public var configMethod: String = ""
        public var router: String = ""
        public var addresses: [String] = []
        public var subnetMasks: [String] = []
      }

      public struct IPv6: Hashable, Sendable {
        public var configMethod: String = ""
        public var router: String = ""
        public var addresses: [String] = []
        public var flags: [String] = []
        public var prefixLength: String = ""
      }

      public var v4: IPv4 = .init()
      public var v6: IPv6 = .init()

      public var dnsServers: [String] = []
    }

    fileprivate var device: NetworkDevice?

    public var hasWLAN: Bool {
      device != nil
    }

    public var interfaceName: String {
      device?.name ?? notApplicable
    }

    public var powerOn: Bool {
      device?.powerOn ?? false
    }

    public var transmitRate: Double {
      device?.transmitRate ?? 0
    }

    public var mtu: Int32 {
      device?.mtu ?? 1500
    }

    public var mediaSubType: String {
      device?.mediaSubType ?? notApplicable
    }

    public var ssid: String {
      device?.ssid ?? notApplicable
    }

    public var bssid: String {
      device?.bssid ?? notApplicable
    }

    public var countryCode: String {
      device?.countryCode ?? notApplicable
    }

    public var rssi: Int {
      device?.rssi ?? 0
    }

    public var noise: Int {
      device?.noise ?? 0
    }

    public var networkService: NetworkService {
      device?.networkService ?? .init()
    }

    public var externalIPAddresses: [String] {
      device?.externalIPAddresses ?? []
    }

    public var addressesUpdatedDate: Date {
      device?.addressesUpdatedDate ?? .now
    }

    public var hardwareAddress: String {
      device?.hardwareAddress ?? notApplicable
    }

    public var activePHYMode: CWPHYMode {
      device?.activePHYMode ?? .modeNone
    }

    public var channelBand: CWChannelBand {
      device?.channelBand ?? .bandUnknown
    }

    public var channelWidth: CWChannelWidth {
      device?.channelWidth ?? .widthUnknown
    }

    public var channelNumber: Int {
      device?.channelNumber ?? 0
    }

    public var channel: String {
      device?.channel ?? notApplicable
    }

    public var security: CWSecurity {
      device?.security ?? .unknown
    }

    public var transmitPower: Int {
      device?.transmitPower ?? 0
    }

    private let logger = Logger(label: "com.apple.CoreWLAN")
    fileprivate nonisolated var client: CWWiFiClient { CWWiFiClient.shared() }

    nonisolated public init() {
      Task.detached(priority: .utility) {
        await self.getWLANInfo()
      }
    }

    deinit {
      try? client.stopMonitoringAllEvents()
      client.delegate = nil
    }

    nonisolated public func requestExternalIPAddresseses() async throws {
      let configuration = URLSessionConfiguration.default
      configuration.proxyConfigurations = []
      configuration.connectionProxyDictionary = [:]

      let session = URLSession(configuration: configuration)

      let (data, _) = try await session.data(from: URL(string: "https://icanhazip.com")!)

      let addresses = String(data: data, encoding: .utf8)?.components(
        separatedBy: .whitespacesAndNewlines
      )
      Task { @MainActor in
        device?.externalIPAddresses = addresses ?? []
        device?.addressesUpdatedDate = .now
      }
    }

    public func startMonitoring() {
      do {
        try client.startMonitoringEvent(with: .ssidDidChange)
        try client.startMonitoringEvent(with: .bssidDidChange)
        try client.startMonitoringEvent(with: .countryCodeDidChange)
        try client.startMonitoringEvent(with: .linkQualityDidChange)
      } catch {
        logger.error("\(error)")
      }
    }

    public func stopMonitoring() {
      do {
        try client.stopMonitoringAllEvents()
      } catch {
        logger.error("\(error)")
      }
    }

    public func getWLANInfo() {
      device = CWWiFiClient.shared().interface() == nil ? nil : device ?? .init()
      if let interface = CWWiFiClient.shared().interface() {
        device?.name = interface.interfaceName ?? notApplicable
        device?.powerOn = interface.powerOn()
        device?.activePHYMode = interface.activePHYMode()
        device?.ssid = interface.ssid() ?? notApplicable
        device?.bssid = interface.bssid() ?? notApplicable
        device?.rssi = interface.rssiValue()
        device?.noise = interface.noiseMeasurement()
        device?.security = interface.security()
        device?.transmitRate = interface.transmitRate()
        device?.countryCode = interface.countryCode() ?? notApplicable
        device?.transmitPower = interface.transmitPower()
        device?.hardwareAddress = interface.hardwareAddress() ?? notApplicable
        device?.channelNumber = interface.wlanChannel()?.channelNumber ?? 11
        device?.channelBand = interface.wlanChannel()?.channelBand ?? .bandUnknown
        device?.channelWidth = interface.wlanChannel()?.channelWidth ?? .widthUnknown
      }

      Task.detached {
        try await self.requestExternalIPAddresseses()
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
        guard SCNetworkInterfaceGetBSDName(interface) as? String == self.interfaceName
        else {
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

      var mediaSubType = notApplicable
      var available: Unmanaged<CFArray>?
      let success = SCNetworkInterfaceCopyMediaOptions(interface, nil, nil, &available, false)
      if success, let available = available?.takeRetainedValue() {
        let copied = SCNetworkInterfaceCopyMediaSubTypes(available) as NSArray?
        mediaSubType = copied?.firstObject as? String ?? notApplicable
      }

      let store = SCDynamicStoreCreate(nil, processName as CFString, nil, nil)
      guard let store, let id = SCNetworkServiceGetServiceID(service) else {
        device?.mtu = mtu
        device?.mediaSubType = mediaSubType
        return
      }
      let dns = extractDNS(from: store, service: id)
      let v4 = extractIPv4Info(from: store, service: id)
      let v6 = extractIPv6Info(from: store, service: id)
      device?.mtu = mtu
      device?.mediaSubType = mediaSubType
      device?.networkService.dnsServers = dns
      device?.networkService.v4 = v4
      device?.networkService.v6 = v6
    }

    nonisolated private func extractDNS(from store: SCDynamicStore, service: CFString)
      -> [String]
    {
      let key = SCDynamicStoreKeyCreateNetworkServiceEntity(
        nil,
        kSCDynamicStoreDomainState,
        service,
        kSCEntNetDNS
      )
      guard let propertyList = SCDynamicStoreCopyValue(store, key) else {
        return .init()
      }
      let serverAddresses = propertyList.object(forKey: kSCPropNetDNSServerAddresses) as? [String]
      guard let serverAddresses else {
        return .init()
      }
      return serverAddresses
    }

    nonisolated private func extractIPv4Info(from store: SCDynamicStore, service: CFString)
      -> NetworkService.IPv4
    {
      var finalize = NetworkService.IPv4()

      var key = SCDynamicStoreKeyCreateNetworkServiceEntity(
        nil,
        kSCDynamicStoreDomainState,
        service,
        kSCEntNetIPv4
      )
      if let propertyList = SCDynamicStoreCopyValue(store, key) {
        finalize.router = propertyList[kSCPropNetIPv4Router] as? String ?? ""
        finalize.addresses = propertyList[kSCPropNetIPv4Addresses] as? [String] ?? []
        finalize.subnetMasks = propertyList[kSCPropNetIPv4SubnetMasks] as? [String] ?? []
      }

      key = SCDynamicStoreKeyCreateNetworkServiceEntity(
        nil,
        kSCDynamicStoreDomainSetup,
        service,
        kSCEntNetIPv4
      )
      if let propertyList = SCDynamicStoreCopyValue(store, key) {
        finalize.configMethod = propertyList[kSCPropNetIPv4ConfigMethod] as? String ?? ""
      }

      return finalize
    }

    nonisolated private func extractIPv6Info(from store: SCDynamicStore, service: CFString)
      -> NetworkService.IPv6
    {
      var finalize = NetworkService.IPv6()

      var key = SCDynamicStoreKeyCreateNetworkServiceEntity(
        nil,
        kSCDynamicStoreDomainState,
        service,
        kSCEntNetIPv6
      )
      if let propertyList = SCDynamicStoreCopyValue(store, key) {
        finalize.router = propertyList[kSCPropNetIPv6Router] as? String ?? ""
        finalize.addresses = propertyList[kSCPropNetIPv6Addresses] as? [String] ?? []
        finalize.flags = propertyList[kSCPropNetIPv6Flags] as? [String] ?? []
        finalize.prefixLength = propertyList[kSCPropNetIPv6PrefixLength] as? String ?? ""
      }

      key = SCDynamicStoreKeyCreateNetworkServiceEntity(
        nil,
        kSCDynamicStoreDomainSetup,
        service,
        kSCEntNetIPv6
      )
      if let propertyList = SCDynamicStoreCopyValue(store, key) {
        finalize.configMethod = propertyList[kSCPropNetIPv6ConfigMethod] as? String ?? ""
      }

      return finalize
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension WLANManager: @preconcurrency CWEventDelegate {

    public func clientConnectionInterrupted() {
      MainActor.assumeIsolated {
        self.getWLANInfo()
      }
    }

    public func clientConnectionInvalidated() {
      MainActor.assumeIsolated {
        self.getWLANInfo()
      }
    }

    public func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
      MainActor.assumeIsolated {
        guard self.device?.name == interfaceName else {
          return
        }
        let ssid = self.client.interface()?.ssid()
        self.device?.ssid = ssid ?? notApplicable
      }
    }

    public func bssidDidChangeForWiFiInterface(withName interfaceName: String) {
      MainActor.assumeIsolated {
        guard self.device?.name == interfaceName else {
          return
        }
        let bssid = self.client.interface()?.bssid()
        self.device?.bssid = bssid ?? notApplicable
      }
    }

    public func countryCodeDidChangeForWiFiInterface(withName interfaceName: String) {
      MainActor.assumeIsolated {
        guard self.device?.name == interfaceName else {
          return
        }
        let countryCode = self.client.interface()?.countryCode()
        self.device?.countryCode = countryCode ?? notApplicable
      }
    }

    public func linkQualityDidChangeForWiFiInterface(
      withName interfaceName: String,
      rssi: Int,
      transmitRate: Double
    ) {
      MainActor.assumeIsolated {
        guard self.device?.name == interfaceName else {
          return
        }
        let rssi = self.client.interface()?.rssiValue()
        let transmitRate = self.client.interface()?.transmitRate()
        self.device?.rssi = rssi ?? 0
        self.device?.transmitRate = transmitRate ?? 0
      }
    }
  }

  extension CWChannelWidth {
    public var localizedName: String {
      switch self {
      case .widthUnknown:
        return "Unknown"
      case .width20MHz:
        return "20MHz"
      case .width40MHz:
        return "40MHz"
      case .width80MHz:
        return "80MHz"
      case .width160MHz:
        return "160MHz"
      @unknown default:
        return notApplicable
      }
    }
  }

  extension CWChannelBand {
    public var localizedName: String {
      switch self {
      case .bandUnknown:
        return "Unknown"
      case .band2GHz:
        return "2.4GHz"
      case .band5GHz:
        return "5GHz"
      case .band6GHz:
        return "6GHz"
      @unknown default:
        return notApplicable
      }
    }
  }

  extension CWPHYMode {
    public var localizedName: String {
      switch self {
      case .modeNone:
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
      @unknown default:
        return notApplicable
      }
    }
  }

  extension CWSecurity {
    public var localizedName: String {
      switch self {
      case .none:
        return "none"
      case .WEP:
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
      case .OWE:
        return "OWE"
      case .oweTransition:
        return "OWE Transition"
      case .unknown:
        return "unknown"
      @unknown default:
        return notApplicable
      }
    }
  }
#endif
