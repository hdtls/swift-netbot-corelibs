//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ProxyPortsEditingSheet: View {
  @Bindable var data: Profile.PersistentModel
  @Environment(\.dismiss) private var dismiss
  @State private var httpListenPort = 6152
  @State private var socksListenPort = 6153

  var body: some View {
    NavigationStack {
      Form {
        TextField("HTTP Proxy Port", value: $httpListenPort, format: .number.grouping(.never))
        TextField("SOCKS5 Proxy Port", value: $socksListenPort, format: .number.grouping(.never))
      }
      .multilineTextAlignment(.trailing)
      .frame(minWidth: 350)
      .padding()
      .navigationTitle("Advanced Proxy Service Settings")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) {
            withAnimation {
              dismiss()
            }
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            withAnimation {
              data.httpListenPort = httpListenPort
              data.socksListenPort = socksListenPort
              dismiss()
            }
          }
        }
      }
    }
  }
}

#if DEBUG
  #Preview("Edit Remote Access Listen Address and Port") {
    PersistentStorePreviewable<Profile.PersistentModel> { models in
      ProxyPortsEditingSheet(data: models.first.unsafelyUnwrapped)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @Query var models: [Profile.PersistentModel]
    ProxyPortsEditingSheet(data: models.first.unsafelyUnwrapped)
  }
#endif
