//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import AnlzrReports
  import Dashboard
  import SwiftUI

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @available(visionOS, unavailable)
  struct RecentConnections: View {

    typealias Data = RecentConnectionsControler

    private let data: Data

    @Binding var selection: Connection?

    init(_ data: Data, selection: Binding<Connection?>) {
      self.data = data
      self._selection = selection
    }

    var body: some View {
      #if os(iOS)
        ConnectionSearchResults(data.searchResult, selection: $selection)
      #else
        ConnectionSearchResults(data.searchResult, selection: $selection)
        RecentConnectionsMenu(data)
      #endif
    }
  }

  #if DEBUG
    #Preview {
      @Previewable let data = RecentConnectionsControler(modelContainer: .makeSharedContext())
      @Previewable @State var selection: Connection?

      RecentConnections(data, selection: $selection)
    }
  #endif
#endif
