//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ProxyEditorSVRIGroup: View {
  @Binding var data: AnyProxy

  #if os(iOS)
    var body: some View {
      Section {
        HStack {
          Text("Server")
          TextField("Address", text: $data.serverAddress)
            .multilineTextAlignment(.trailing)
        }

        HStack {
          Text("Port")
          TextField("Port", value: $data.port, format: .number.grouping(.never))
            .multilineTextAlignment(.trailing)
        }
      } header: {
        Text("Server Information")
      }
    }
  #else
    var body: some View {
      GroupBox {
        VStack(alignment: .leading) {
          Text("Server")
          HStack {
            TextField("Address", text: $data.serverAddress, prompt: Text("Address"))
              .labelsHidden()
            Text(verbatim: ":")
            TextField(
              "Port",
              value: $data.port,
              format: .number.grouping(.never),
              prompt: Text("Port")
            )
            .labelsHidden()
          }
        }
      } label: {
        Text("Server Information")
      }
    }
  #endif
}

#if DEBUG
  #Preview {
    BindingPreviewable(AnyProxy()) { $data in
      ProxyEditorSVRIGroup(data: $data)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxy()
    ProxyEditorSVRIGroup(data: $data)
  }
#endif
