//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import AnlzrReports
  import _PersistentStore
  import Dashboard
  import SwiftUI

  @available(iOS 17.0, macOS 14.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  public struct ContentView: View {
    @AppStorage(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
    private var enabledHTTPCapabilities = CapabilityFlags()

    @State private var connection: Connection?

    public typealias Data = RecentConnectionsControler

    private let data: Data

    public init(_ data: Data = Data()) {
      self.data = data
    }

    public var body: some View {
      NavigationSplitView {
        Dashboard(data)
          .navigationSplitViewColumnWidth(235)
      } detail: {
        VSplitView {
          RecentConnections(data, selection: $connection)

          if let connection {
            ConnectionDetail(connection)
              .padding(.horizontal)
              .padding(.vertical, 8)
              .frame(minHeight: 260, maxHeight: .infinity, alignment: .top)
          }
        }
        .frame(minWidth: 835)
      }
    }
  }

  #if DEBUG
    @available(iOS 18.0, macOS 15.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    #Preview {
      @Previewable let data = RecentConnectionsControler(modelContainer: .makeSharedContext())

      ContentView(data)
    }
  #endif
#endif
