//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct StubbedHTTPResponseGallery: View {

  typealias Data = StubbedHTTPResponse.PersistentModel

  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @Query(sort: \Data.creationDate) private var searchResults: [Data]
  @State private var selectedResponseRewriteID: Data.ID?
  @State private var presentingEditor = false
  @State private var persistentModel: Data?

  #if os(iOS)
    var body: some View {
      List {
        Section {
          ForEach(searchResults) { item in
            Button {

            } label: {
              ListRow(text: item.pattern, detailText: detailText(item: item))
            }
            .foregroundColor(.primary)
          }
          .onDelete { offsets in
            for offset in offsets {
              let model = searchResults[offset]
              modelContext.delete(model)
            }
          }
        } header: {
          Text("All Rules")
        }
      }
      .navigationTitle("Mock")
      .toolbar {
        addStubbedResponseButton
      }
    }
  #else
    var body: some View {
      Section {
        VStack(alignment: .leading, spacing: 0) {
          Table(searchResults, selection: $selectedResponseRewriteID) {
            TableColumn("Pattern", value: \.pattern)
            TableColumn("Status") {
              Text("\($0.statusCode) \($0.reasonPhrase)")
            }
            TableColumn("Headers") {
              Text($0.additionalHTTPFields, format: .httpFields)
            }
            TableColumn("Data") {
              Text(detailText(item: $0))
            }
          }
          Divider()
          HStack {
            addStubbedResponseButton

            Button {
              let responseRewrite = searchResults.first {
                $0.persistentModelID == selectedResponseRewriteID
              }
              guard let responseRewrite else {
                return
              }
              modelContext.delete(responseRewrite)
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
        Text("Map Local")
          .textCase(.uppercase)
          .font(.headline)
          .foregroundColor(.blue)
      }
    }
  #endif

  @MainActor private var addStubbedResponseButton: some View {
    Button {
      persistentModel = nil
      presentingEditor = true
    } label: {
      Image(systemName: "plus")
    }
    .sheet(isPresented: $presentingEditor) { [persistentModel] in
      StubbedHTTPResponseEditingSheet(data: persistentModel)
    }
  }

  private func detailText(item: StubbedHTTPResponse.PersistentModel) -> String {
    guard let url = item.bodyContentsURL else {
      return ""
    }
    guard url.isFileURL else {
      return url.absoluteString
    }
    return url.lastPathComponent
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    StubbedHTTPResponseGallery()
  }
#endif
