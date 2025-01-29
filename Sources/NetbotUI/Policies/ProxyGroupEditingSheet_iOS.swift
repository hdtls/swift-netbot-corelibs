//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

#if os(iOS)
  struct ProxyGroupEditingSheet: View {
    @AppStorage(Prefs.Name.profileURL, store: .applicationGroup)
    private var profileURL = URL.profile

    @AppStorage(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
    private var selectionRecordForGroups = SelectionRecordForGroups()

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.profileAssistant) private var profileAssistant

    @Query private var profiles: [Profile.PersistentModel]

    @State private var data: AnyProxyGroup

    private let persistentModel: AnyProxyGroup.PersistentModel?
    private var titleKey: LocalizedStringKey {
      persistentModel == nil ? "New Policy Group" : "Edit Policy Group"
    }
    private var available: [AnyProxy.PersistentModel] {
      guard let profile = profiles.first else {
        return []
      }
      return profile.lazyProxies.sorted(using: SortDescriptor(\.creationDate)).filter {
        !data.lazyProxies.contains($0.name)
      }
    }

    init(data: AnyProxyGroup.PersistentModel?) {
      self.persistentModel = data
      if let data {
        self._data = .init(initialValue: .init(persistentModel: data))
      } else {
        self._data = .init(initialValue: .init())
      }

      var fd = FetchDescriptor<Profile.PersistentModel>()
      fd.predicate = #Predicate { $0.url == profileURL }
      fd.relationshipKeyPathsForPrefetching = [\.lazyProxies]
      self._profiles = Query(fd)
    }

    var body: some View {
      NavigationStack {
        List {
          Section {
            HStack {
              Text("Group Name")
              TextField("Group Name", text: $data.name)
                .multilineTextAlignment(.trailing)
            }
          } footer: {
            Text("Select which policy will be used on the user interface.")
          }

          Section {
            ForEach(data.lazyProxies, id: \.self) { name in
              if let proxy = profiles.first?.lazyProxies.first(where: { $0.name == name }) {
                HStack {
                  VStack(alignment: .leading) {
                    Text(proxy.name)
                    Text(proxy.kind.rawValue)
                      .font(.caption)
                  }
                  Spacer()
                  Button {
                    withAnimation {
                      data.lazyProxies.removeAll(where: { $0 == name })
                    }
                  } label: {
                    Image(systemName: "minus")
                      .symbolVariant(.circle)
                      .foregroundColor(.red)
                  }
                }
              }
            }
          } header: {
            Text("Included")
              .textCase(.uppercase)
          }

          Section {
            ForEach(available) { proxy in
              HStack {
                VStack(alignment: .leading) {
                  Text(proxy.name)
                  Text(proxy.kind.rawValue)
                    .font(.caption)
                }
                Spacer()
                Button {
                  withAnimation {
                    data.lazyProxies.append(proxy.name)
                  }
                } label: {
                  Image(systemName: "plus")
                    .symbolVariant(.circle)
                    .foregroundColor(.blue)
                }
              }
            }
          } header: {
            Text("Available")
              .textCase(.uppercase)
          }
        }
        .navigationTitle(titleKey)
        .toolbar {
          toolbarItems
        }
        .onChange(of: profileURL) {
          withAnimation {
            dismiss()
          }
        }
      }
    }

    @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
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
      }
    }

    private func save() {
      do {
        guard let profile = profiles.first else {
          return
        }

        var persistentModel = self.persistentModel
        if let persistentModel {
          Task(priority: .background) {
            try await profileAssistant.replace(.init(persistentModel: persistentModel), with: data)
          }
          selectionRecordForGroups.replaceKey(persistentModel.name, with: data.name)
          // Update selection if policy is removed from policy group.
          let proxyName = selectionRecordForGroups[data.name]
          guard !data.lazyProxies.contains(where: { $0 == proxyName }) else {
            return
          }
          // Set selected policy name to the first object.
          selectionRecordForGroups[data.name] = data.lazyProxies.first
        } else {
          persistentModel = AnyProxyGroup.PersistentModel()
          modelContext.insert(persistentModel.unsafelyUnwrapped)
          Task(priority: .background) {
            try await profileAssistant.insert(data)
          }
        }

        if let persistentModel {
          persistentModel.mergeValues(data)
          persistentModel.lazyProxies = profile.lazyProxies.filter {
            data.lazyProxies.contains($0.name)
          }
        }
        try modelContext.save()
      } catch {}
    }
  }
#endif

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("Edit Proxy Group", traits: .persistentStore()) {
    @Previewable @Query var models: [AnyProxyGroup.PersistentModel]
    ProxyGroupEditingSheet(data: models.first)
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("New Proxy Group", traits: .persistentStore()) {
    ProxyGroupEditingSheet(data: nil)
  }
#endif
