//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ProxyGroupStack: View {

  typealias Data = AnyProxyGroup.PersistentModel

  @AppStorage(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
  private var selectionRecordForGroups = SelectionRecordForGroups()
  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @Query(sort: \Data.creationDate) private var searchResults: [Data]
  @State private var presentingEditor = false
  @State private var persistentModel: Data?

  var body: some View {
    Section {
      ForEach(searchResults) { group in
        NavigationLink(value: group) {
          ProxyGroupCell(data: group)
        }
      }
      .onMove { source, destination in
        // TODO: Move Policy Groups from Offsets to Offset
        Task(priority: .background) {
          try await profileAssistant.movePolicyGroups(fromOffsets: source, toOffset: destination)
        }
      }
      .onDelete { offsets in
        // TODO: Remove Policy Groups at Offsets
        Task(priority: .background) {
          try await profileAssistant.removePolicyGroups(atOffsets: offsets)
        }
        selectionRecordForGroups.removeKeys(offsets.map({ searchResults[$0].name }))
      }

      Button {
        persistentModel = nil
        presentingEditor = true
      } label: {
        HStack {
          Image(systemName: "plus")
            .symbolVariant(.circle.fill)
            .padding(4)
            .foregroundColor(.green)

          Text("Add Policy Group")
        }
        .padding([.top, .bottom], 5)
      }
      .buttonStyle(.plain)
      .sheet(isPresented: $presentingEditor) { [persistentModel] in
        ProxyGroupEditingSheet(data: persistentModel)
      }
    } header: {
      Text("Policy Group")
        .textCase(.uppercase)
        .foregroundColor(.blue)
    }
  }
}

#if DEBUG
  #Preview {
    PersistentStorePreviewable {
      List {
        ProxyGroupStack()
      }
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    List {
      ProxyGroupStack()
    }
  }
#endif
