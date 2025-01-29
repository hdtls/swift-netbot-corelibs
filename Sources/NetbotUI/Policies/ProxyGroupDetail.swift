//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ProxyGroupDetail: View {
  @AppStorage(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
  private var selectionRecordForGroups = SelectionRecordForGroups()
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @State private var presentingProxyGroupEditor = false

  private let persistentModel: AnyProxyGroup.PersistentModel

  init(data: AnyProxyGroup.PersistentModel) {
    persistentModel = data
  }

  var body: some View {
    List {
      Section {
        HStack {
          Text("Group Name")
          Spacer()
          Text(persistentModel.name)
        }
      }

      Section {
        ForEach(persistentModel.lazyProxies) { proxy in
          Button {
            selectionRecordForGroups[persistentModel.name] = proxy.name
          } label: {
            HStack {
              VStack(alignment: .leading) {
                Text(proxy.name)
                Text(proxy.kind.rawValue)
                  .font(.caption)
              }
              Spacer()
              if selectionRecordForGroups[persistentModel.name] == proxy.name {
                Image(systemName: "checkmark")
                  .foregroundColor(.accentColor)
              }
            }
            .foregroundColor(.primary)
          }
        }
      } header: {
        Text("Proxies")
          .textCase(.uppercase)

      } footer: {
        Text("Select which proxy will be use to process requests")
      }

      Button("Delete Proxy Group", role: .destructive) {
        modelContext.delete(persistentModel)
        let model = AnyProxyGroup(persistentModel: persistentModel)
        Task(priority: .background) {
          try await profileAssistant.delete(model)
        }
        selectionRecordForGroups[persistentModel.name] = nil
        dismiss()
      }
    }
    .navigationTitle("Proxy Group")
    .toolbar {
      Button("Edit") {
        presentingProxyGroupEditor = true
      }
    }
    .sheet(isPresented: $presentingProxyGroupEditor) { [persistentModel] in
      ProxyGroupEditingSheet(data: persistentModel)
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @Query var models: [AnyProxyGroup.PersistentModel]
    NavigationStack {
      ProxyGroupDetail(data: models.first.unsafelyUnwrapped)
    }
  }
#endif
