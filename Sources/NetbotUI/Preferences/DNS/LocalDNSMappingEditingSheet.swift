//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct LocalDNSMappingEditingSheet: View {

  @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant

  @State private var dns = ""
  @State private var address = ""
  @State private var isOn = false
  @State private var data: DNSMapping

  private let persistentModel: DNSMapping.PersistentModel?
  private var titleKey: LocalizedStringKey {
    persistentModel == nil ? "New Local DNS Mapping" : "Edit Local DNS Mapping"
  }

  init(data: DNSMapping.PersistentModel?) {
    self.persistentModel = data
    if let data {
      self._data = State(initialValue: .init(persistentModel: data))
    } else {
      self._data = State(initialValue: .init())
    }
  }

  var body: some View {
    NavigationStack {
      GroupBox {
        Form {
          TextField("Domain:", text: $data.domainName, prompt: Text(""))
          TextField("Data", text: $address, prompt: Text("IP Address or another domain"))
            .disabled(isOn)
          Toggle("Use specific upstream DNS server", isOn: $isOn)
            .onChange(of: isOn) {
              dns = ""
              address = ""
            }
          TextField("Server", text: $dns, prompt: Text("Server IP address"))
            .disabled(!isOn)
          TextField("Comment", text: $data.note, prompt: Text("Optional"))
        }
        .fixedSize()
        .padding()
      }
      .padding()
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
        }
      }
    }
  }

  private func save() {
    do {
      var fd = FetchDescriptor<Profile.PersistentModel>()
      fd.predicate = #Predicate { $0.url == profileURL }
      fd.sortBy = [.init(\.creationDate)]
      guard let profile = try modelContext.fetch(fd).first else {
        return
      }

      data.value = isOn ? dns : address
      data.kind = isOn ? .dns : data.value.isIPAddress() ? .mapping : .cname

      if let persistentModel {
        let original = DNSMapping(persistentModel: persistentModel)
        Task(priority: .background) {
          try await profileAssistant.replace(original, with: data)
        }
      } else {
        let persistentModel = DNSMapping.PersistentModel()
        persistentModel.mergeValues(data)
        profile.lazyDNSMappings.append(persistentModel)
        Task(priority: .background) {
          try await profileAssistant.insert(data)
        }
      }

    } catch {
      assertionFailure()
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("Edit Local DNS Mapping", traits: .persistentStore()) {
    @Previewable @Query var models: [DNSMapping.PersistentModel]
    LocalDNSMappingEditingSheet(data: models.first)
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("New Local DNS Mapping", traits: .persistentStore()) {
    LocalDNSMappingEditingSheet(data: nil)
  }
#endif
