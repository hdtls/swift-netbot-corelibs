//
// See LICENSE.txt for license information
//

#if os(macOS) && EXTENDED_ALL
  import SwiftUI

  struct DevicesPage: View {
    enum SortOptions: CaseIterable, CustomStringConvertible, Hashable {
      case traffic
      case speed
      case name
      case ip
      case dhcpLastSeen

      public var description: String {
        switch self {
        case .traffic:
          return "Sort by Traffic"
        case .speed:
          return "Sort by Speed"
        case .name:
          return "Sort by Name"
        case .ip:
          return "Sort by IP"
        case .dhcpLastSeen:
          return "Sort by DHCP Last Seen"
        }
      }
    }

    @State private var sortOptions: SortOptions = .traffic
    @State private var turnOnDHCPServerMode = false

    var body: some View {
      VStack(alignment: .leading) {
        HStack {
          Text("Device")
            .font(.largeTitle)
            .bold()

          Spacer()

          Picker("", selection: $sortOptions) {
            ForEach(SortOptions.allCases, id: \.self) { options in
              Text(options.description)
            }
          }
          .pickerStyle(.menu)
          .labelsHidden()
          .frame(width: 180)
        }
        .padding(.bottom)

        HStack {
          VStack(alignment: .leading) {
            ZStack {
              ContentUnavailableView {
                Text("No Devices")
                  .font(.body)
              }
              ScrollView {

              }
            }
            Divider()
              .padding(.bottom, 8)

            HStack {
              Toggle("DHCP Server", isOn: $turnOnDHCPServerMode)
                .toggleStyle(.switch)

              Spacer()

              Button {

              } label: {
                Image(systemName: "gearshape")
              }
              .buttonStyle(.plain)
            }

            Text(
              "You can use Netbot as a DHCP server for your LAN and take over the network of other devices with Netbot gateway mode with a simple click."
            )
            .font(.footnote)
            .foregroundColor(.secondary)
          }

          ZStack {
            ContentUnavailableView {
              Text("No Selection")
                .font(.body)
            }
            ScrollView {

            }
          }
          .cornerRadius(10)
          .overlay {
            RoundedRectangle(cornerRadius: 10)
              .stroke(Color.gray.opacity(0.3), style: .init(dash: [3], dashPhase: 3))
          }
        }
      }
      .padding()
      .navigationTitle("Devices")
    }
  }

  #if DEBUG
    #Preview {
      DevicesPage()
    }
  #endif
#endif
