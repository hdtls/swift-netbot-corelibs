//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ProxyEditorWSGroup: View {
  @Binding var data: AnyProxy

  #if os(iOS)
    var body: some View {
      Section {
        Toggle("WebSocket", isOn: $data.ws.isEnabled)
        if data.ws.isEnabled {
          HStack {
            Text("Path:")
            TextField("", text: $data.ws.uri)
              .multilineTextAlignment(.trailing)
              .labelsHidden()
          }
          HStack {
            Text("Additional Headers:")
            TextField(
              "", value: $data.ws.additionalHTTPFields, format: .httpFields,
              prompt: Text("Optional, Seperated by |")
            )
            .multilineTextAlignment(.trailing)
            .labelsHidden()
          }
        }
      } header: {
        Text("WebSocket")
      }
    }
  #else
    var body: some View {
      GroupBox {
        VStack(alignment: .leading) {
          Toggle("Enable WebSocket", isOn: $data.ws.isEnabled)
          Group {
            HStack {
              Text("Path:")
              TextField("", text: $data.ws.uri)
                .labelsHidden()
            }
            Text("Additional HTTP Fields:")
            TextField(
              "",
              value: $data.ws.additionalHTTPFields, format: .httpFields,
              prompt: Text("Optional, Seperated by |")
            )
          }
          .disabled(!data.ws.isEnabled)
        }
      } label: {
        Text("WebSocket")
      }
    }
  #endif
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxy()
    ProxyEditorWSGroup(data: $data)
  }
#endif
