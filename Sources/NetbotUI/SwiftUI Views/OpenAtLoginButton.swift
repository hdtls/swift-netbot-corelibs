//
// See LICENSE.txt for license information
//

#if os(macOS)
  import ServiceManagement
  import SwiftUI

  struct OpenAtLoginButton: View {
    @State private var openAtLogin = false

    var body: some View {
      Toggle("Open \(ProcessInfo.processInfo.processName) at Login", isOn: $openAtLogin)
        .onChange(of: openAtLogin) { old, enabled in
          Task {
            do {
              if enabled {
                try SMAppService.mainApp.register()
              } else {
                try await SMAppService.mainApp.unregister()
              }
            } catch {
              openAtLogin = old
            }
          }
        }
        .onAppear {
          openAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
  }

  #if DEBUG
    #Preview {
      OpenAtLoginButton()
    }
  #endif
#endif
