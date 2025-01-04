//
// See LICENSE.txt for license information
//

public import CoreTransferable
import Netbot
public import SwiftData
import SwiftUI

struct ForwardingRulesSearchResults: View {

  typealias Data = AnyForwardingRule.PersistentModel

  @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile
  @Binding private var searchText: String
  @Binding private var selection: PersistentIdentifier?
  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @Query private var searchResults: [Data]

  init(searchText: Binding<String>, selection: Binding<PersistentIdentifier?>) {
    self._searchText = searchText
    self._selection = selection
    var fd = FetchDescriptor<Data>()
    let term = searchText.wrappedValue
    fd.predicate = #Predicate { term.isEmpty || $0.value.contains(term) }
    fd.sortBy = [SortDescriptor(\.order)]
    self._searchResults = Query(fd)
  }

  var body: some View {
    Table(of: Data.self, selection: $selection) {
      TableColumn("") {
        @Bindable var data = $0
        Toggle("", isOn: $data.isEnabled)
          .onChange(of: data.isEnabled) { oldValue, newValue in
            let current = AnyForwardingRule(persistentModel: data)
            var original = current
            original.isEnabled = oldValue
            Task(priority: .background) {
              try await profileAssistant.replace(original, with: current)
            }
          }
          .labelsHidden()
      }
      .width(20)
      TableColumn("ID") {
        Text("\(searchResults.firstIndex(of: $0) ?? 0)")
      }
      .width(min: 20, max: 80)
      TableColumn("Type", value: \.kind.rawValue)
      TableColumn("Value", value: \.value)
      TableColumn("Policy") {
        Text($0.lazyProxy?.name ?? $0.lazyProxyGroup?.name ?? "")
      }
      TableColumn("Comment", value: \.comment)
    } rows: {
      ForEach(searchResults) {
        TableRow($0)
          .draggable($0.persistentModelID)
      }
      .dropDestination(for: PersistentIdentifier.self) { destination, transferables in
        let offsets = transferables.compactMap { persistentModelID in
          searchResults.firstIndex(where: { $0.persistentModelID == persistentModelID })
        }
        let source = IndexSet(offsets)
        moveRules(searchResults, fromOffsets: source, toOffset: destination)
      }
    }
  }

  private func moveRules(_ rules: [Data], fromOffsets source: IndexSet, toOffset offset: Int) {
    try? modelContext.transaction {
      var searchResults = rules
      searchResults.move(fromOffsets: source, toOffset: offset)
      for (offset, model) in searchResults.enumerated() {
        model.order = offset
      }
    }

    Task(priority: .background) {
      try await profileAssistant.moveRules(fromOffsets: source, toOffset: offset)
    }
  }
}

extension PersistentIdentifier: @retroactive Transferable {
  public static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(for: PersistentIdentifier.self, contentType: .data)
  }
}
