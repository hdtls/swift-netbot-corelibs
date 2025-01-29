//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

/// A proxies container view that arranges its child views in a stack that grows vertically.
struct ProxyStack: View {

  typealias Data = AnyProxy.PersistentModel

  @AppStorage(Prefs.Name.selectionRecordForGroups, store: .applicationGroup)
  private var selectionRecordForGroups = SelectionRecordForGroups()
  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @Query(sort: \Data.creationDate) private var searchResults: [Data]
  @State private var presentingEditor = false
  @State private var persistentModel: Data?

  init() {
    let term = AnyProxy.Source.userDefined.rawValue
    _searchResults = Query(filter: #Predicate { $0.source == term }, sort: \.creationDate)
  }

  var body: some View {
    Section {
      ForEach(searchResults) { data in
        NavigationLink(value: data) {
          ProxyCell(data: data)
            .moveDisabled(!data.isEditable)
            .deleteDisabled(!data.isEditable)
        }
      }
      .onMove { source, destination in
        // TODO: Reorder Proxies
        Task(priority: .background) {
          try await profileAssistant.moveProxies(fromOffsets: source, toOffset: destination)
        }
      }
      .onDelete { offsets in
        for offset in offsets {
          let model = searchResults[offset]
          modelContext.delete(model)
        }
        Task(priority: .background) {
          try await profileAssistant.removeProxies(atOffsets: offsets)
        }
        selectionRecordForGroups.removeValues(offsets.map({ searchResults[$0].name }))
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

          Text("Add Proxy")
        }
        .padding([.top, .bottom], 5)
      }
      .buttonStyle(.plain)
      .sheet(isPresented: $presentingEditor) { [persistentModel] in
        ProxyEditingSheet(data: persistentModel)
      }
    } header: {
      Text("Proxy")
        .textCase(.uppercase)
        .foregroundColor(.purple)
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    NavigationStack {
      List {
        ProxyStack()
      }
    }
  }
#endif
