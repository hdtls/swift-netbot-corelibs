//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

@Editable<URLRewrite> struct URLRewriteEditingSheet: View {

  private var titleKey: LocalizedStringKey {
    persistentModel == nil ? "New Redirection Rule" : "Edit Redirection Rule"
  }

  var body: some View {
    NavigationStack {
      URLRewriteForm(data: $data)
        .navigationTitle(titleKey)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", role: .cancel) {
              withAnimation {
                dismiss()
              }
            }
          }

          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              withAnimation {
                save()
                dismiss()
              }
            }
          }
        }
    }
  }
}

#if DEBUG
  extension URLRewriteEditingSheet {

    fileprivate init(_data data: URLRewrite.PersistentModel?) {
      self.init(data: data)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("Edit URLRewrite", traits: .persistentStore()) {
    @Previewable @Query var models: [URLRewrite.PersistentModel]
    URLRewriteEditingSheet(_data: models.first)
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("New URLRewrite", traits: .persistentStore()) {
    URLRewriteEditingSheet(_data: nil)
  }
#endif
