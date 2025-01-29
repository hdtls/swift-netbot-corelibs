//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ForwardingRuleDetail: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @State private var presentingRuleEditor = false
  @State private var data = AnyForwardingRule()
  private let persistentModel: AnyForwardingRule.PersistentModel

  init(data: AnyForwardingRule.PersistentModel) {
    self.persistentModel = data
  }

  var body: some View {
    Group {
      #if os(iOS)
        ForwardingRuleForm(data: $data)
          .disabled(true)
      #else
        List {
          ForwardingRuleForm(data: $data)
            .disabled(true)
        }
      #endif
    }
    .navigationTitle(Text("Rule"))
    .toolbar {
      toolbarItems
    }
    .sheet(isPresented: $presentingRuleEditor) { [persistentModel] in
      ForwardingRuleEditingSheet(data: persistentModel)
        #if os(macOS)
          .frame(width: 500)
        #endif
    }
  }

  @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
    #if os(macOS)
      // Make buttons alignment to trailing
      ToolbarItem {
        Spacer()
      }
    #endif

    ToolbarItem {
      Menu {
        Button {
          data = AnyForwardingRule()
          presentingRuleEditor = true
        } label: {
          Label("New Rule", systemImage: "plus")
            .symbolVariant(.circle)
        }

        Button {
          data = .init(persistentModel: persistentModel)
          presentingRuleEditor = true
        } label: {
          Label("Edit Rule", systemImage: "square.and.pencil")
        }
      } label: {
        Image(systemName: "square.and.pencil")
      }
      .menuIndicator(.hidden)
    }

    ToolbarItemGroup(placement: toolbarPlacement) {
      #if os(iOS)
        // Make Trash button alignment to trailing
        Spacer()
      #endif

      Button(role: .destructive) {
        modelContext.delete(persistentModel)
        let model = AnyForwardingRule(persistentModel: persistentModel)
        Task(priority: .background) {
          try await profileAssistant.delete(model)
        }
      } label: {
        Image(systemName: "trash")
      }
    }
  }

  private var toolbarPlacement: ToolbarItemPlacement {
    var placement: ToolbarItemPlacement = .automatic
    #if os(iOS)
      if UIDevice.current.userInterfaceIdiom == .phone {
        placement = .bottomBar
      }
    #endif
    return placement
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @Query var models: [AnyForwardingRule.PersistentModel]
    NavigationStack {
      ForwardingRuleDetail(data: models.first.unsafelyUnwrapped)
    }
  }
#endif
