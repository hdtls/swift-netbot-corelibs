//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Netbot
  import SwiftUI

  struct NetworkInterfaceActivity: View {
    let monitor: WLANManager
    let locationManager: LocationManager

    var body: some View {
      HStack {
        GroupBox {
          VStack(alignment: .leading) {
            Label("External IP Address", systemImage: "globe")
              .font(.headline)
              .foregroundColor(.blue)
            Text(monitor.externalIPAddresses.first ?? "N/A")
              .font(.title)
              .bold()
          }
          .padding(.horizontal)
          .padding(.vertical, 8)
          .frame(minWidth: 200, alignment: .leading)
          .overlay(alignment: .topTrailing) {
            Menu("...") {
              Section {
                Text("Last Updated: \(Text(monitor.addressesUpdatedDate, style: .offset)) ago")
                Button("Refresh Now") {
                  Task {
                    try await monitor.requestExternalIPAddresseses()
                  }
                }
              }

              Section {
                Button("Copy Address") {
                  NSPasteboard.general.setString(
                    monitor.externalIPAddresses.first ?? "",
                    forType: .string
                  )
                }
                .disabled(monitor.externalIPAddresses.isEmpty)
              }
            }
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
            .fixedSize()
            .padding(.trailing, 8)
          }
        }

        if monitor.hasWLAN {
          GroupBox {
            VStack(alignment: .leading) {
              Label("Wi-Fi", systemImage: "wifi")
                .font(.headline)
                .foregroundColor(.green)
              Text(monitor.addresses.v4.addresses.first ?? "N/A")
                .font(.title)
                .bold()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(minWidth: 200, alignment: .leading)
            .overlay(alignment: .topTrailing) {
              WLANMenu(monitor: monitor)
                .padding(.trailing, 8)
            }
            .task {
              monitor.getWLANInfo()
            }
          }
        }
      }
      .onAppear {
        try? locationManager.authorizeLocationServices()
        locationManager.startUpdatingLocation()
        monitor.startMonitoring()
      }
      .onDisappear {
        locationManager.stopUpdatingLocation()
        monitor.stopMonitoring()
      }
    }
  }

  #if DEBUG
    #Preview {
      NetworkInterfaceActivity(monitor: .init(), locationManager: .init())
    }
  #endif
#endif
