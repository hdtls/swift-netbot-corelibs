//
// See LICENSE.txt for license information
//

import SwiftUI

extension ContentView {

  struct Sidebar: View {
    @Binding var selection: Pages

    var body: some View {
      List(
        selection: .init(get: { selection }, set: { if let newValue = $0 { selection = newValue } })
      ) {
        #if EXTENDED_ALL
          NavigationLink(value: Pages.activity) {
            Pages.activity.label
          }

          Section("Clients") {
            NavigationLink(value: Pages.process) {
              Pages.process.label
            }

            NavigationLink(value: Pages.device) {
              Pages.device.label
            }
          }
        #endif

        Section("Proxies") {
          NavigationLink(value: Pages.policy) {
            Pages.policy.label
          }

          NavigationLink(value: Pages.forwardingRule) {
            Pages.forwardingRule.label
          }
        }

        Section("Capabilities") {
          NavigationLink(value: Pages.httpCapture) {
            Pages.httpCapture.label
          }

          NavigationLink(value: Pages.httpsDecryption) {
            Pages.httpsDecryption.label
          }

          NavigationLink(value: Pages.httpRewrite) {
            Pages.httpRewrite.label
          }
        }

        #if os(macOS)
          Section {
            OpenDashboardButton()
              .buttonStyle(.plain)
          }
          .collapsible(false)
        #endif
      }
      .navigationTitle(Text(verbatim: "Netbot"))
    }
  }
}

#if DEBUG
  #Preview {
    @Previewable @State var page: Pages = .policy

    NavigationStack {
      ContentView.Sidebar(selection: $page)
    }
  }
#endif
