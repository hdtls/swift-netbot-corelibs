//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Netbot
  import SwiftData
  import SwiftUI

  struct LocalDNSMappingSettings: View {

    typealias Data = DNSMapping.PersistentModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.profileAssistant) private var profileAssistant

    @Query(sort: \Data.creationDate) private var searchResults: [Data]

    @State private var selectedMappingID: Data.ID?
    @State private var presentingEditor = false
    @State private var persistentModel: Data?

    var body: some View {
      Section("Local DNS Mapping") {
        VStack(alignment: .leading, spacing: 0) {
          Table(searchResults, selection: $selectedMappingID) {
            TableColumn("") { mapping in
              Toggle(
                "", isOn: .init(get: { mapping.isEnabled }, set: { mapping.isEnabled = $0 }))
            }
            TableColumn("Domain", value: \.domainName)
            TableColumn("Data") { mapping in
              if mapping.kind == .mapping {
                Text(mapping.value)
              }
            }
            TableColumn("DNS Server") { mapping in
              if mapping.kind == .cname || mapping.kind == .dns {
                Text(mapping.value)
              }
            }
            TableColumn("Comment", value: \.note)
          }
          .frame(minHeight: 190)

          Divider()
          HStack {
            Button {
              persistentModel = nil
              presentingEditor = true
            } label: {
              Image(systemName: "plus")
            }

            Button {
              delete()
            } label: {
              Image(systemName: "minus")
            }
            .disabled(selectedMappingID == nil)
          }
          .padding([.horizontal])
          .padding(.vertical, 8)
        }

        .cornerRadius(2)
        .overlay {
          RoundedRectangle(cornerRadius: 2)
            .stroke(.gray.opacity(0.2))
        }
      }
      .sheet(isPresented: $presentingEditor) { [persistentModel] in
        LocalDNSMappingEditingSheet(data: persistentModel)
      }
    }

    private func delete() {
      guard let mapping = searchResults.first(where: { $0.persistentModelID == selectedMappingID })
      else {
        return
      }
      modelContext.delete(mapping)
      let model = DNSMapping(persistentModel: mapping)
      Task(priority: .background) {
        try await profileAssistant.delete(model)
      }
    }
  }

  #if DEBUG
    #Preview {
      PersistentStorePreviewable {
        LocalDNSMappingSettings()
      }
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    #Preview(traits: .persistentStore()) {
      LocalDNSMappingSettings()
    }
  #endif
#endif
