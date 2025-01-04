//
// See LICENSE.txt for license information
//

#if os(macOS)
  import CoreLocation
  import Netbot
  import SwiftUI

  struct WLANMenu: View {
    let monitor: WLANManager

    var body: some View {
      Menu("...") {
        Section {
          Button("BSD Name: \(monitor.interfaceName)") {}
          Button("Transmit Rate: \(Int(monitor.transmitRate)) Mbps") {}
        }

        Section {
          Button("MAC: \(monitor.hardwareAddress)") {}
          Button("MTU: \(monitor.mtu)") {}
          Button("Media SubType: \(monitor.mediaSubType)") {}
        } header: {
          Text("Hardware")
        }

        Section {
          Button("Config Method: \(monitor.addresses.v4.configMethod)") {}
          ForEach(monitor.addresses.v4.addresses, id: \.self) {
            Button("Address: \($0)") {}
          }
          if !monitor.addresses.v4.router.isEmpty {
            Button("Router: \(monitor.addresses.v4.router)") {}
          }
        } header: {
          Text("IPv4")
        }

        Section {
          Button("Config Method: \(monitor.addresses.v6.configMethod)") {}
          ForEach(monitor.addresses.v6.addresses, id: \.self) {
            Button("Address: \($0)") {}
          }
          if !monitor.addresses.v6.router.isEmpty {
            Button("Router: \(monitor.addresses.v6.router)") {}
          }
        } header: {
          Text("IPv6")
        }

        Section {
          ForEach(monitor.addresses.dns.addresses, id: \.self) {
            Button("Server: \($0)") {}
          }
        } header: {
          Text("DNS")
        }

        Section {
          Button("SSID: \(monitor.ssid)") {}
          Button("BSSID: \(monitor.bssid)") {}
          Button("PHY Mode: \(monitor.activePHYMode.localizedName)") {}
          Button("Channel: \(monitor.channel)") {}
          Button("Country Code: \(monitor.countryCode)") {}
          Button("Security: \(monitor.security.localizedName)") {}
          Button("RSSI: \(monitor.rssi) dBm") {}
          Button("Noise: \(monitor.noise) dBm") {}
          Button("Transmit Power: \(monitor.transmitPower) mW") {}
        } header: {
          Text("AirPort")
        }
      }
      .menuIndicator(.hidden)
      .menuStyle(.borderlessButton)
      .fixedSize()
    }
  }

  #if DEBUG
    #Preview {
      WLANMenu(monitor: WLANManager())
        .frame(width: 100, height: 100)
    }
  #endif
#endif
