//
// See LICENSE.txt for license information
//

#if os(macOS)
  import SwiftUI

  let appURL = Bundle.main.bundleURL.appendingPathComponent(
    "Contents/Applications/Netbot Dashboard.app"
  )

  struct OpenDashboardButton: View {
    var body: some View {
      Button {
        NSWorkspace.shared.openApplication(at: appURL, configuration: .init())
      } label: {
        Pages.dashboard.label
      }
    }
  }

  #if DEBUG
    #Preview {
      OpenDashboardButton()
    }
  #endif
#endif
