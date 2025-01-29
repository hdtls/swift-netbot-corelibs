//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

@Editable<StubbedHTTPResponse> struct StubbedHTTPResponseEditingSheet: View {

  private var titleKey: LocalizedStringKey {
    persistentModel == nil ? "New HTTP Response Stub" : "Edit HTTP Response Stub"
  }

  var body: some View {
    NavigationStack {
      StubbedHTTPResponseForm(data: $data)
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
  extension StubbedHTTPResponseEditingSheet {

    fileprivate init(_data data: StubbedHTTPResponse.PersistentModel?) {
      self.init(data: data)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("Edit HTTP Response Stub", traits: .persistentStore()) {
    @Previewable @Query var models: [StubbedHTTPResponse.PersistentModel]
    StubbedHTTPResponseEditingSheet(_data: models.first)
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview("New HTTP Response Stub", traits: .persistentStore()) {
    StubbedHTTPResponseEditingSheet(_data: nil)
  }
#endif
