//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct HTTPFieldsRewriteForm: View {
  @Binding var data: HTTPFieldsRewrite

  #if os(iOS)
    var body: some View {
      Form {
        Section {
          Picker("HTTP Direction", selection: $data.direction) {
            ForEach(HTTPFieldsRewrite.Direction.allCases, id: \.self) {
              Text($0.rawValue)
            }
          }

          Picker("Action", selection: $data.action) {
            ForEach(HTTPFieldsRewrite.Action.allCases, id: \.self) {
              Text($0.localizedName)
            }
          }
        } header: {
          Text("Mode")
        } footer: {
          footer
        }

        Section {
          TextField("URL RegEx", text: $data.pattern, prompt: Text("Regular Expression"))
        } header: {
          Text("URL Regex")
        }

        Section {
          TextField("Name", text: $data.name, prompt: Text("Field Name"))
        } header: {
          Text("Header Field Name")
        }

        if data.action != .remove {
          Section {
            TextField("Value", text: $data.value, prompt: Text("Field Value"))
          } header: {
            Text("Header Field Value")
          }
        }
      }
    }
  #else
    var body: some View {
      VStack(alignment: .leading) {
        Form {
          Picker("HTTP Direction", selection: $data.direction) {
            ForEach(HTTPFieldsRewrite.Direction.allCases, id: \.self) {
              Text($0.rawValue)
            }
          }

          Picker("Action", selection: $data.action) {
            ForEach(HTTPFieldsRewrite.Action.allCases, id: \.self) {
              Text($0.localizedName)
            }
          }

          TextField("URL Pattern", text: $data.pattern, prompt: Text("Regular Expression"))

          TextField("Field", text: $data.name, prompt: Text("Field Name"))

          if data.action != .remove {
            TextField("Value", text: $data.value, prompt: valueFieldPrompt)

            if data.action == .replace {
              TextField("Replacement", text: $data.value, prompt: Text("New Field Value"))
            }
          }
        }
      }
      .padding(.horizontal, 32)
      .padding(.vertical)
      .frame(width: 470)
    }
  #endif

  private var valueFieldPrompt: Text {
    switch data.action {
    case .add:
      return Text("Field Value")
    case .remove:
      return Text(verbatim: "")
    case .replace:
      return Text("Regular Expression")
    }
  }

  @ViewBuilder private var footer: some View {
    switch data.action {
    case .add:
      Text("Append a new field to the header, even if the field already exists.")
    case .remove:
      Text("Remove a header field from the header.")
    case .replace:
      Text(
        "Replace a header value in the header, If the header field doesn't exist, nothing happens."
      )
    }
  }
}

#if DEBUG
  #Preview {
    BindingPreviewable(HTTPFieldsRewrite()) { $data in
      HTTPFieldsRewriteForm(data: $data)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = HTTPFieldsRewrite()
    HTTPFieldsRewriteForm(data: $data)
  }
#endif
