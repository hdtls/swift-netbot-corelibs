//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ForwardingRulesPage: View {

  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @State private var selectedRuleID: PersistentIdentifier?
  @State private var searchText = ""
  @State private var presentingEditor = false
  @State private var persistentModel: AnyForwardingRule.PersistentModel?

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Rule")
          .font(.largeTitle)
          .bold()

        Spacer()

        TextField("", text: $searchText, prompt: Text("Search"))
          .labelsHidden()
          .textFieldStyle(.searchable(text: $searchText))
          .frame(maxWidth: 330)
      }

      Text("Rules are evaluated in priority order, from top to bottom.")
        .font(.footnote)
        .foregroundColor(.secondary)
        .padding(.bottom)

      VStack(alignment: .leading, spacing: 0) {
        ForwardingRulesSearchResults(searchText: $searchText, selection: $selectedRuleID)
          .contextMenu(forSelectionType: PersistentIdentifier.self) {
            if let persistentModelID = $0.first {
              Button("Edit") {
                beginEditing(persistentModelID)
              }

              if searchText.isEmpty {
                Button("Delete...", role: .destructive) {
                  delete(persistentModelID)
                }
              }
            }
          } primaryAction: {
            if let persistentModelID = $0.first {
              beginEditing(persistentModelID)
            }
          }
        Divider()
        HStack {
          Button {
            persistentModel = nil
            presentingEditor = true
          } label: {
            Image(systemName: "plus")
          }
          .disabled(!searchText.isEmpty)

          Button {
            guard let selectedRuleID else { return }
            delete(selectedRuleID)
          } label: {
            Image(systemName: "minus")
          }
          .disabled(selectedRuleID == nil || !searchText.isEmpty)
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
    .padding()
    .sheet(isPresented: $presentingEditor) { [persistentModel] in
      ForwardingRuleEditingSheet(data: persistentModel)
    }
    .navigationTitle("Rule")
    #if os(macOS)
      .navigationSubtitle("Rules are evaluated in priority order, from top to bottom")
    #endif
  }

  private func beginEditing(_ persistentModelID: PersistentIdentifier) {
    persistentModel = modelContext.registeredModel(for: persistentModelID)
    presentingEditor = true
  }

  private func delete(_ persistentModelID: PersistentIdentifier) {
    guard
      let persistentModel: AnyForwardingRule.PersistentModel = modelContext.registeredModel(
        for: persistentModelID)
    else {
      return
    }
    modelContext.delete(persistentModel)

    let model = AnyForwardingRule(persistentModel: persistentModel)
    Task(priority: .background) {
      try await profileAssistant.delete(model)
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    ForwardingRulesPage()
  }
#endif
