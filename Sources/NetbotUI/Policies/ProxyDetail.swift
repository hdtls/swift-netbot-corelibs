//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ProxyDetail: View {
  @Environment(\.modelContext) private var modelContext
  @State private var presentingEditor = false
  private let persistentModel: AnyProxy.PersistentModel

  init(data: AnyProxy.PersistentModel) {
    persistentModel = data
  }

  var body: some View {
    Group {
      #if os(iOS)
        ProxyEditor(data: .constant(.init(persistentModel: persistentModel)))
          .disabled(true)
      #else
        List {
          ProxyEditor(data: .constant(.init(persistentModel: persistentModel)))
            .disabled(true)
        }
      #endif
    }
    .toolbar {
      // Disable edit button when showing placeholder.
      Button("Edit") {
        presentingEditor = true
      }
    }
    .sheet(isPresented: $presentingEditor) { [persistentModel] in
      ProxyEditingSheet(data: persistentModel)
    }
    .navigationTitle("Proxy")
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @Query var models: [AnyProxy.PersistentModel]
    NavigationStack {
      ProxyDetail(data: models.first.unsafelyUnwrapped)
    }
  }
#endif
