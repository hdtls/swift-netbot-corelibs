//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct URLRewriteGallery: View {

  typealias Data = URLRewrite.PersistentModel

  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @Query(sort: \Data.creationDate) private var searchResults: [Data]
  @State private var selectedURLRewriteID: Data.ID?
  @State private var presentingEditor = false
  @State private var persistentModel: Data?

  #if os(iOS)
    var body: some View {
      List {
        Section {
          ForEach(searchResults) { item in
            Button {

            } label: {
              ListRow(text: item.pattern, detailText: item.destination)
            }
            .foregroundColor(.primary)
          }
          .onDelete { offsets in
            for offset in offsets {
              let model = searchResults[offset]
              modelContext.delete(model)
            }
            Task(priority: .background) {
              try await profileAssistant.removeURLRewrites(atOffsets: offsets)
            }
          }
        } header: {
          Text("All Rules")
        }
      }
      .navigationTitle("URL Rewrite")
      .toolbar {
        addRedirectRuleButton
      }
    }
  #else
    var body: some View {
      Section {
        VStack(alignment: .leading, spacing: 0) {
          Table(searchResults, selection: $selectedURLRewriteID) {
            TableColumn("Type", value: \.type.localizedName)
            TableColumn("Pattern", value: \.pattern)
            TableColumn("Replacement", value: \.destination)
          }
          Divider()
          HStack {
            addRedirectRuleButton

            Button {
              let urlRewrite = searchResults.first { $0.persistentModelID == selectedURLRewriteID }
              guard let urlRewrite else {
                return
              }
              modelContext.delete(urlRewrite)
              let model = URLRewrite(persistentModel: urlRewrite)
              Task(priority: .background) {
                try await profileAssistant.delete(model)
              }
            } label: {
              Image(systemName: "minus")
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 4)
        }
        .cornerRadius(2)
        .overlay {
          RoundedRectangle(cornerRadius: 2)
            .stroke(.gray.opacity(0.2))
        }
      } header: {
        Text("Map Remote")
          .textCase(.uppercase)
          .font(.headline)
          .foregroundColor(.orange)
      }
    }
  #endif

  @MainActor private var addRedirectRuleButton: some View {
    Button {
      persistentModel = nil
      presentingEditor = true
    } label: {
      Image(systemName: "plus")
    }
    .sheet(isPresented: $presentingEditor) { [persistentModel] in
      URLRewriteEditingSheet(data: persistentModel)
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("New URLRewrite", traits: .persistentStore()) {
    #if os(iOS)
      NavigationStack {
        URLRewriteGallery()
      }
    #else
      VStack(alignment: .leading) {
        URLRewriteGallery()
      }
    #endif
  }
#endif
