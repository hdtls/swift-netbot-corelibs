//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ProxyGroupGrid: View {

  typealias Data = AnyProxyGroup.PersistentModel

  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @Query(sort: \Data.creationDate) private var searchResults: [Data]
  @State private var presentingEditor = false
  @State private var persistentModel: Data?

  var body: some View {
    Section {
      ForEach(searchResults) { data in
        GroupBox {
          ProxyGroupCell(data: data)
            .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        }
        .contextMenu {
          Button("Edit") {
            persistentModel = data
            presentingEditor = true
          }

          Button("Duplicate") {
            guard let lazyProfile = data.lazyProfile else {
              return
            }
            var copy = AnyProxyGroup(persistentModel: data)
            copy.name = searchResults.map({ $0.name }).duplicate(data.name)
            let persistentModel = AnyProxyGroup.PersistentModel()
            persistentModel.mergeValues(copy)
            lazyProfile.lazyProxyGroups.append(persistentModel)
            modelContext.insert(persistentModel)
            Task(priority: .background) {
              try await profileAssistant.insert(copy)
            }

            // Also make relationship between group and proxy.
            persistentModel.lazyProxies = data.lazyProxies
          }

          Button("Delete...", role: .destructive) {
            modelContext.delete(data)
            let model = AnyProxyGroup(persistentModel: data)
            Task(priority: .background) {
              try await profileAssistant.delete(model)
            }
          }
        }
        .accessibilityIdentifier("ProxyGroup - Tile")
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
      .help("Add New Proxy Group")
    } header: {
      Text("Policy Group")
        .textCase(.uppercase)
        .foregroundColor(.blue)
      Divider()
    }
    .sheet(isPresented: $presentingEditor) { [persistentModel] in
      ProxyGroupEditingSheet(data: persistentModel)
    }
  }
}

#if DEBUG
  #Preview {
    PersistentStorePreviewable {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 150))]) {
          ProxyGroupGrid()
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
        ProxyGroupGrid()
      }
    }
    #if os(macOS)
      .frame(width: 650, height: 510)
    #endif
  }
#endif
