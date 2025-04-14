//
// See LICENSE.txt for license information
//

#if canImport(SwiftUI)
  import Dashboard
  import _PersistentStore
  import SwiftData
  import SwiftUI

  struct RecentConnectionsMenu: View {

    @AppStorage(Prefs.Name.enabledHTTPCapabilities, store: .applicationGroup)
    private var enabledHTTPCapabilities = CapabilityFlags()

    private let data: RecentConnectionsControler

    init(_ data: RecentConnectionsControler) {
      self.data = data
    }

    var body: some View {
      HStack {
        Button("Clear") {
          Task {
            await data.erase()
          }
        }

        Button("Reload") {
          Task {
            await data.update()
          }
        }

        Button {
          if enabledHTTPCapabilities.contains(.httpCapture) {
            enabledHTTPCapabilities.remove(.httpCapture)
          } else {
            enabledHTTPCapabilities.insert(.httpCapture)
          }
        } label: {
          if enabledHTTPCapabilities.contains(.httpCapture) {
            Text("Disable HTTP Capture")
          } else {
            Text("Enable HTTP Capture")
          }
        }

        Button {
          if enabledHTTPCapabilities.contains(.httpsDecryption) {
            enabledHTTPCapabilities.remove(.httpsDecryption)
          } else {
            enabledHTTPCapabilities.insert(.httpsDecryption)
          }
        } label: {
          if enabledHTTPCapabilities.contains(.httpsDecryption) {
            Text("Disable MitM")
          } else {
            Text("Enable MitM")
          }
        }

        Spacer()
      }
      .padding(.horizontal)
      .padding(.vertical, 4)
    }
  }

  #if DEBUG
    #Preview {
      @Previewable let data = RecentConnectionsControler(modelContainer: .makeSharedContext())

      RecentConnectionsMenu(data)
    }
  #endif
#endif
