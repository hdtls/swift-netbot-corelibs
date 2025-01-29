//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct HTTPFieldsRewriteGallery: View {

  typealias Data = HTTPFieldsRewrite.PersistentModel

  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @Query(sort: \Data.creationDate) private var searchResults: [Data]
  @State private var selectedHTTPFieldsRewriteID: Data.ID?
  @State private var presentingEditor = false
  @State private var persistentModel: Data?

  #if os(iOS)
    var body: some View {
      List {
        Section {
          ForEach(searchResults) { item in
            Button {

            } label: {
              ListRow(
                text: item.pattern,
                detailText:
                  "\(item.action.rawValue.uppercased()) field \(item.name): \(item.value)"
              )
            }
            .foregroundColor(.primary)
          }
          .onDelete { offsets in
            try? modelContext.transaction {
              for offset in offsets {
                let model = searchResults[offset]
                modelContext.delete(model)
              }
            }
          }
        } header: {
          Text("All Rules")
        }
      }
      .navigationTitle("HTTP Headers Rewrite")
      .toolbar {
        addHTTPFieldsRewriteButton
      }
    }
  #else
    var body: some View {
      Section {
        VStack(alignment: .leading, spacing: 0) {
          Table(searchResults, selection: $selectedHTTPFieldsRewriteID) {
            TableColumn("Pattern", value: \.pattern)
            TableColumn("Action", value: \.action.rawValue)
            TableColumn("Field", value: \.name)
            TableColumn("Value", value: \.value)
            TableColumn("Replacement", value: \.replacement)
          }
          Divider()
          HStack {
            addHTTPFieldsRewriteButton

            Button {
              let httpFieldsRewrite = searchResults.first {
                $0.persistentModelID == selectedHTTPFieldsRewriteID
              }
              guard let httpFieldsRewrite else {
                return
              }
              modelContext.delete(httpFieldsRewrite)
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
        Text("Header Rewrite")
          .textCase(.uppercase)
          .font(.headline)
          .foregroundColor(.green)
      }
    }
  #endif

  @MainActor private var addHTTPFieldsRewriteButton: some View {
    Button {
      persistentModel = nil
      presentingEditor = true
    } label: {
      Image(systemName: "plus")
    }
    .sheet(isPresented: $presentingEditor) { [persistentModel] in
      HTTPFieldsRewriteEditingSheet(data: persistentModel)
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    #if os(iOS)
      HTTPFieldsRewriteGallery()
    #else
      VStack(alignment: .leading) {
        HTTPFieldsRewriteGallery()
      }
      .padding()
    #endif
  }
#endif
