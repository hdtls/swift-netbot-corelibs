//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ForwardingRuleEditingSheet: View {
  @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.profileAssistant) private var profileAssistant
  @State private var data: AnyForwardingRule

  private let persistentModel: AnyForwardingRule.PersistentModel?
  private var title: LocalizedStringKey {
    persistentModel == nil ? "New Standard Rule" : "Edit Standard Rule"
  }
  private var canMarkAsComplete: Bool {
    guard persistentModel == nil else {
      // Always return true for edit existing forwardingRule.
      return true
    }

    // Value of FINAL forwardingRule may leave empty.
    if data.kind == .final {
      return true
    }

    // Value is required for rules except FINAL.
    return !data.value.isEmpty
  }

  init(data: AnyForwardingRule.PersistentModel?) {
    self.persistentModel = data
    if let data {
      self._data = State(initialValue: .init(persistentModel: data))
    } else {
      self._data = State(initialValue: .init())
    }
  }

  var body: some View {
    NavigationStack {
      ForwardingRuleForm(data: $data)
        .navigationTitle(title)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
          }

          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              withAnimation {
                save()
                dismiss()
              }
            }
            .disabled(!canMarkAsComplete)
          }
        }
    }
  }

  private func save() {
    do {
      var fd = FetchDescriptor<Profile.PersistentModel>()
      fd.predicate = #Predicate { $0.url == profileURL }
      fd.sortBy = [.init(\.creationDate)]
      guard let profile = try modelContext.fetch(fd).first else {
        return
      }

      var persistentModel = self.persistentModel
      if let persistentModel {
        let original = AnyForwardingRule(persistentModel: persistentModel)
        Task(priority: .background) {
          try await profileAssistant.replace(original, with: data)
        }
      } else {
        Task(priority: .background) {
          try await profileAssistant.insert(data)
        }
        persistentModel = AnyForwardingRule.PersistentModel()
        profile.lazyForwardingRules.sort(using: SortDescriptor(\.order))
        // Advence sort priority of each forwardingRule.
        for model in profile.lazyForwardingRules {
          model.order += 1
        }

        // Optional binding to silence NeverForceUnwrapp
        if let persistentModel {
          profile.lazyForwardingRules.insert(persistentModel, at: 0)
        }
      }

      if let persistentModel {
        persistentModel.mergeValues(data)
        persistentModel.lazyProxy = profile.lazyProxies.first { $0.name == data.foreignKey }
        persistentModel.lazyProxyGroup = profile.lazyProxyGroups.first {
          $0.name == data.foreignKey
        }
      }
    } catch {
      assertionFailure(error.localizedDescription)
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("Edit Rule", traits: .persistentStore()) {
    @Previewable @Query var models: [AnyForwardingRule.PersistentModel]
    ForwardingRuleEditingSheet(data: models.first)
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("New Rule", traits: .persistentStore()) {
    ForwardingRuleEditingSheet(data: nil)
  }
#endif
