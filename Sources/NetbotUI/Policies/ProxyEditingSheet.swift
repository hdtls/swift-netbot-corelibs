//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

@Editable<AnyProxy> struct ProxyEditingSheet: View {

  @AppStorage(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
  private var selectionRecordForGroups = SelectionRecordForGroups()

  private var titleKey: LocalizedStringKey {
    persistentModel == nil ? "New Proxy" : "Edit Proxy"
  }

  var body: some View {
    NavigationStack {
      ProxyEditor(data: $data)
        .navigationTitle(titleKey)
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
                save()
                dismiss()
              }
            }
            .disabled(data.serverAddress.isEmpty)
          }
        }
    }
  }

  private func save() {
    do {
      if let persistentModel {
        let original = AnyProxy(persistentModel: persistentModel)
        Task(priority: .background) {
          try await profileAssistant.replace(original, with: data)
        }
        selectionRecordForGroups.replaceValue(persistentModel.name, with: data.name)
        persistentModel.mergeValues(data)
      } else {
        var fd = FetchDescriptor<Profile.PersistentModel>()
        fd.predicate = #Predicate { $0.url == profileURL }
        fd.sortBy = [SortDescriptor(\.creationDate)]
        guard let profile = try modelContext.fetch(fd).first else {
          return
        }
        let persistentModel = AnyProxy.PersistentModel()
        persistentModel.mergeValues(data)
        profile.lazyProxies.append(persistentModel)
        Task(priority: .background) {
          try await profileAssistant.insert(data)
        }
      }

      try modelContext.save()
    } catch {
      assertionFailure(error.localizedDescription)
    }
  }
}

#if DEBUG
  extension ProxyEditingSheet {

    fileprivate init(_data data: AnyProxy.PersistentModel?) {
      self.init(data: data)
    }
  }

  #Preview("Edit Proxy") {
    PersistentStorePreviewable<AnyProxy.PersistentModel> { models in
      ProxyEditingSheet(_data: models.first)
    }
  }

  #Preview("New Proxy") {
    PersistentStorePreviewable {
      ProxyEditingSheet(_data: nil)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("Edit Proxy", traits: .persistentStore()) {
    @Previewable @Query var models: [AnyProxy.PersistentModel]
    ProxyEditingSheet(_data: models.first)
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("New Proxy", traits: .persistentStore()) {
    ProxyEditingSheet(_data: nil)
  }
#endif
