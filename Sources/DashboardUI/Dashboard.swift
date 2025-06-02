//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import Dashboard
  import SwiftData
  import SwiftUI

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  struct Dashboard: View {

    typealias Element = Connection

    @Binding var options: ConnectionFilter?
    @Environment(RecentConnectionsControler.self) private var connections
    @State private var segmented: ConnectionFilter = .client(nil)

    private var searchResult: [Element] { connections.search(tokens: []) }

    private var processes: [ProcessReport] {
      var seen = Set<String?>()
      return searchResult.compactMap {
        seen.insert($0.processReport.processName).inserted ? $0.processReport : nil
      }
    }

    private var hostnames: [String] {
      var seen = Set<String?>()
      return searchResult.compactMap {
        let hostname = $0.originalRequest.host(percentEncoded: false)
        return seen.insert(hostname).inserted ? hostname : nil
      }
    }

    init(options: Binding<ConnectionFilter?>) {
      self._options = options
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

        List(selection: $options) {
          switch segmented {
          case .client:
            Section("All Clients") {
              NavigationLink("All Clients", value: ConnectionFilter.client(nil))
            }
            Section("Local Clients") {
              #if os(macOS)
                ForEach(processes, id: \.processName) { process in
                  NavigationLink(
                    value: ConnectionFilter.client(process.processName)
                  ) {
                    Label(
                      title: {
                        Text(process.processName ?? "Unknown")
                      },
                      icon: {
                        process.processIcon
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
              ForEach(hostnames, id: \.self) {
                NavigationLink($0, value: ConnectionFilter.hostname($0))
              }
            }
          }
        }
      }
      .onChange(of: segmented) {
        options = segmented
      }
    }
  }

  #if DEBUG
    @available(swift 5.9)
    @available(iOS 18.0, macOS 15.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    #Preview(traits: .persistentStore()) {
      @Previewable @State var options: ConnectionFilter?

      NavigationStack {
        Dashboard(options: $options)
      }
    }
  #endif
#endif
