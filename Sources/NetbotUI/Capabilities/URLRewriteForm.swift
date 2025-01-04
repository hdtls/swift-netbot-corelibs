//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct URLRewriteForm: View {
  @Binding var data: URLRewrite

  var body: some View {
    Form {
      Section {
        Picker(selection: $data.type) {
          ForEach(URLRewrite.RewriteType.allCases, id: \.self) {
            Text($0.localizedName)
          }
        } label: {
          #if os(iOS)
            Text("Code")
          #else
            Text("Status Code")
          #endif
        }
        #if !os(iOS)
          .frame(maxWidth: 200)
        #endif

        #if !os(iOS)
          TextField("Pattern", text: $data.pattern, prompt: Text("URL Regular Expression"))

          TextField(
            "Replacement",
            text: $data.destination,
            prompt: Text("Destination URL or Path")
          )
        #endif
      } header: {
        #if os(iOS)
          Text("Response Status")
        #endif
      } footer: {
        Text(
          "Netbot will simply return a \(data.type.localizedName) response. HTTPS requests can be redirected if MitM is enabled."
        )
        .font(.footnote)
        .foregroundColor(.secondary)
      }

      #if os(iOS)
        Section {
          TextField("Pattern", text: $data.pattern, prompt: Text("URL Regular Expression"))
        } header: {
          Text("Regular Expression")
        }

        Section {
          TextField(
            "Replacement",
            text: $data.destination,
            prompt: Text("Destination URL or Path")
          )
        } header: {
          Text("Replacement")
        }
      #endif
    }
    #if !os(iOS)
      .padding(.horizontal, 32)
      .padding(.vertical)
      .frame(width: 470)
    #endif
  }
}

#if DEBUG
  #Preview {
    BindingPreviewable(URLRewrite()) { $data in
      URLRewriteForm(data: $data)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = URLRewrite()
    URLRewriteForm(data: $data)
  }
#endif
