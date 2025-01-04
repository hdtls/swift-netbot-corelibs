//
// See LICENSE.txt for license information
//

import SwiftUI

struct PickSSLPKCS12BundleButton<Label>: View where Label: View {
  @State private var fileURL: URL?
  @State private var passphrase: String = ""
  @State private var presentingPasswordAlert = false
  private let label: () -> Label
  private let onCompletion: (URL, String) -> Void

  init(action: @escaping (URL, String) -> Void, @ViewBuilder label: @escaping () -> Label) {
    self.label = label
    self.onCompletion = action
  }

  init(_ titleKey: LocalizedStringKey, action: @escaping (URL, String) -> Void)
  where Label == Text {
    self.label = { Text(titleKey) }
    self.onCompletion = action
  }

  var body: some View {
    PickURLButton(allowedContentTypes: [.pkcs12]) {
      switch $0 {
      case .success(let success):
        fileURL = success
        presentingPasswordAlert = true
      case .failure(let failure):
        assertionFailure(failure.localizedDescription)
      }
    } label: {
      label()
    }
    .alert(
      "Enter password for: \(fileURL?.lastPathComponent ?? "nil")",
      isPresented: $presentingPasswordAlert
    ) {
      TextField("PKCS#12 passphrase", text: $passphrase)

      Button("Cancel", role: .cancel) {
        fileURL = nil
        presentingPasswordAlert = false
      }

      Button("OK") {
        guard let fileURL else {
          presentingPasswordAlert = false
          return
        }

        onCompletion(fileURL, passphrase)
        presentingPasswordAlert = false
        passphrase = ""
      }
    }
  }
}

#if DEBUG
  #Preview {
    PickSSLPKCS12BundleButton("") { _, _ in }
  }
#endif
