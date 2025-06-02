//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import Dashboard
  import SwiftUI

  @available(iOS 17.0, macOS 14.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  public struct ContentView: View {

    @AppStorage(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
    private var enabledHTTPCapabilities = CapabilityFlags()

    @State private var options: ConnectionFilter?

    public init() {}

    public var body: some View {
      NavigationSplitView {
        Dashboard(options: $options)
          .navigationSplitViewColumnWidth(235)
      } detail: {
        RecentConnections(options: $options)
      }
    }
  }

  #if DEBUG
    @available(iOS 18.0, macOS 15.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(visionOS, unavailable)
    #Preview(traits: .persistentStore()) {
      ContentView()
    }
  #endif
#endif
