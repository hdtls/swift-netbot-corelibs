//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ProxyEditorOBFSGroup: View {
  @Binding var data: AnyProxy

  #if os(iOS)
    var body: some View {
      Section {
        Toggle("Obfuscation", isOn: $data.obfuscation.isEnabled)
        if data.obfuscation.isEnabled {
          Picker(selection: $data.obfuscation.strategy) {
            ForEach(AnyProxy.Obfuscation.Strategy.allCases, id: \.self) {
              Text($0.localizedName)
                .textCase(.uppercase)
            }
          } label: {
            Text("Protocol")
          }
          HStack {
            Text("Host")
            TextField("", text: $data.obfuscation.hostname)
              .multilineTextAlignment(.trailing)
          }
        }
      } header: {
        Text("Obfuscation")
      }
    }
  #else
    var body: some View {
      GroupBox {
        Form {
          Picker(selection: $data.obfuscation.strategy) {
            ForEach(AnyProxy.Obfuscation.Strategy.allCases, id: \.self) {
              Text($0.localizedName)
                .textCase(.uppercase)
            }
          } label: {
            Text("Protocol")
          }
          .pickerStyle(.segmented)

          TextField("Hostname", text: $data.obfuscation.hostname, prompt: Text("Optional"))
            .accessibilityIdentifier("Hostname")
        }
      } label: {
        Text("Obfuscation")
      }
    }
  #endif
}

#if DEBUG
  #Preview {
    BindingPreviewable(AnyProxy()) { $data in
      ProxyEditorOBFSGroup(data: $data)
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxy()
    ProxyEditorOBFSGroup(data: $data)
  }
#endif
