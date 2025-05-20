//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import Dashboard
  import SwiftUI
  import AnlzrReports

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  struct Dashboard: View {
    @State private var filter: ConnectionFilter?
    @State private var segmented: ConnectionFilter = .client(nil)

    typealias Data = RecentConnectionsControler

    private let data: Data

    init(_ data: Data) {
      self.data = data
    }

    var body: some View {
      VStack {
        Picker("", selection: $segmented) {
          Text("By Client")
            .tag(ConnectionFilter.client(nil))
          Text("By Host")
            .tag(ConnectionFilter.hostname(nil))
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .frame(width: 185)

        List(selection: $filter) {
          switch segmented {
          case .client:
            Section("All Clients") {
              NavigationLink("All Clients", value: ConnectionFilter.client(nil))
            }
            Section("Local Clients") {
              #if os(macOS)
                ForEach(data.processes, id: \.taskIdentifier) { connection in
                  NavigationLink(
                    value: ConnectionFilter.client(connection.processReport.processName)
                  ) {
                    Label(
                      title: {
                        Text(connection.processReport.processName ?? "Unknown")
                      },
                      icon: {
                        connection.processReport.processIcon
                          .frame(width: 20, height: 20)
                      }
                    )
                  }
                }
              #endif
            }
            Section("Remote Clients") {
            }
          case .hostname:
            Section("All Hosts") {
              NavigationLink("All Hosts", value: ConnectionFilter.hostname(nil))
            }
            Section("Remote Hosts") {
              ForEach(data.hostnames, id: \.self) {
                NavigationLink($0, value: ConnectionFilter.hostname($0))
              }
            }
          }
        }
      }
      .onChange(of: segmented) {
        filter = segmented
      }
      .onChange(of: filter) {
        data.query(filter: filter)
      }
    }
  }

  #if DEBUG
    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    #Preview {
      @Previewable let data = RecentConnectionsControler(modelContainer: .makeSharedContext())

      NavigationStack {
        Dashboard(data)
      }
    }
  #endif
#endif
