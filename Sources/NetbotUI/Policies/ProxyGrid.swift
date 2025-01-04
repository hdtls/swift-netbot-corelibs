//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

/// A proxies container view that arranges its child views in a grid that grows vertically.
struct ProxyGrid: View {

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
        GroupBox {
          ProxyCell(data: data)
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        }
        .contextMenu {
          if data.isEditable {
            Button("Edit") {
              persistentModel = data
              presentingEditor = true
            }

            Button("Duplicate") {
              guard let lazyProfile = data.lazyProfile else {
                return
              }

              var copy = AnyProxy(persistentModel: data)
              copy.name = searchResults.map({ $0.name }).duplicate(data.name)
              let persistentModel = AnyProxy.PersistentModel()
              persistentModel.mergeValues(copy)
              modelContext.insert(persistentModel)
              persistentModel.lazyProfile = lazyProfile
              Task(priority: .background) {
                try await profileAssistant.insert(copy)
              }
            }

            Button("Delete...", role: .destructive) {
              modelContext.delete(data)
              let model = AnyProxy(persistentModel: data)
              Task(priority: .background) {
                try await profileAssistant.delete(model)
              }
              selectionRecordForGroups.removeValue(data.name)
            }
          }
        }
        .accessibilityIdentifier("Proxy - Tile")
      }

      Button {
        persistentModel = nil
        presentingEditor = true
      } label: {
        GroupBox {
          ZStack {
            Image(systemName: "plus")
              .padding(4)
              .background {
                RoundedRectangle(cornerRadius: 5)
                  .opacity(0.1)
              }
          }
          .frame(maxWidth: .infinity, minHeight: 70)
        }
        .groupBoxStyle(.dashedBorder)
      }
      .buttonStyle(.plain)
      .help("Add New Proxy")
      .sheet(isPresented: $presentingEditor) { [persistentModel] in
        ProxyEditingSheet(data: persistentModel)
      }
    } header: {
      Text("Proxy")
        .textCase(.uppercase)
        .foregroundColor(.purple)
      Divider()
    }
  }
}

#if DEBUG
  #Preview {
    PersistentStorePreviewable {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 150))]) {
          ProxyGrid()
        }
      }
      #if os(macOS)
        .frame(width: 650, height: 510)
      #endif
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    ScrollView {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 150))]) {
        ProxyGrid()
      }
    }
    #if os(macOS)
      .frame(width: 650, height: 510)
    #endif
  }
#endif
