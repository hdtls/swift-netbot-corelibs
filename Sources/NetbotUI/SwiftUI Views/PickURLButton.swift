//
// See LICENSE.txt for license information
//

import SwiftUI
import UniformTypeIdentifiers

struct PickURLButton<Label>: View where Label: View {
  @State private var isPresented = false
  private let label: () -> Label
  private let allowedContentTypes: [UTType]
  private let onCompletion: (Result<URL, any Error>) -> Void

  init(
    allowedContentTypes: [UTType],
    action: @escaping (Result<URL, any Error>) -> Void,
    @ViewBuilder label: @escaping () -> Label
  ) {
    self.label = label
    self.allowedContentTypes = allowedContentTypes
    self.onCompletion = action
  }

  init(
    _ titleKey: LocalizedStringKey,
    allowedContentTypes: [UTType],
    action: @escaping (Result<URL, any Error>) -> Void
  ) where Label == Text {
    self.label = { Text(titleKey) }
    self.allowedContentTypes = allowedContentTypes
    self.onCompletion = action
  }

  var body: some View {
    Button {
      isPresented = true
    } label: {
      label()
    }
    .fileImporter(isPresented: $isPresented, allowedContentTypes: allowedContentTypes) { result in
      switch result {
      case .success(let file):
        // gain access to the directory
        if !file.startAccessingSecurityScopedResource() { return }
        // access the directory URL
        onCompletion(.success(file))
        // release access
        file.stopAccessingSecurityScopedResource()
      case .failure(let error):
        // handle error
        onCompletion(.failure(error))
      }
    }
  }
}

#if DEBUG
  #Preview {
    PickURLButton("Pick File URL", allowedContentTypes: [.directory]) { result in

    }
  }
#endif
