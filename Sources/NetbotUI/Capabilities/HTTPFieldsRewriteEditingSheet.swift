//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

@Editable<HTTPFieldsRewrite> struct HTTPFieldsRewriteEditingSheet: View {

  var body: some View {
    NavigationStack {
      HTTPFieldsRewriteForm(data: $data)
        .navigationTitle("New HTTP Fields Rewrite")
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
  extension HTTPFieldsRewriteEditingSheet {

    fileprivate init(_data data: HTTPFieldsRewrite.PersistentModel?) {
      self.init(data: data)
    }
  }

  #Preview("Edit HTTPFields Rewrite") {
    PersistentStorePreviewable<HTTPFieldsRewrite.PersistentModel> { models in
      HTTPFieldsRewriteEditingSheet(_data: models.first)
    }
  }

  #Preview("New HTTPFields Rewrite") {
    PersistentStorePreviewable {
      HTTPFieldsRewriteEditingSheet(_data: nil)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @Query var models: [HTTPFieldsRewrite.PersistentModel]
    HTTPFieldsRewriteEditingSheet(_data: models.first)
  }
#endif
