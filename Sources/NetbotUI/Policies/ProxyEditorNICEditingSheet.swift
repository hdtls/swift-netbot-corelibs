//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Netbot
  import SwiftUI

  struct ProxyEditorNICEditingSheet: View {
    @Binding var data: AnyProxy
    @Environment(\.dismiss) private var dismiss
    @State private var backToDefaultIfNICUnavailable = false
    @State private var name = ""

    var body: some View {
      NavigationStack {
        Form {
          TextField("Name", text: $name, prompt: Text("Network Interface Name"))
          Toggle(isOn: $backToDefaultIfNICUnavailable) {
            Text("Allow use the default interface if the specified one is unavailable")
            Text(
              "When the option is true, if the desired interface is not available, \(ProcessInfo.processInfo.processName) is allowed to use the default interface to setup the connection. Otherwise the connection fails directly."
            )
            .foregroundStyle(.secondary)
            .font(.footnote)
          }
        }
        .frame(width: 450)
        .fixedSize()
        .padding()
        .navigationTitle("Specified Interface")
        .navigationSubtitle("You may force proxy to go through the specific network interface")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", role: .cancel) {
              dismiss()
            }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              data.engress.backToDefaultIfNICUnavailable = backToDefaultIfNICUnavailable
              data.engress.interfaceName = name
              dismiss()
            }
          }
        }
        .onAppear {
          backToDefaultIfNICUnavailable = data.engress.backToDefaultIfNICUnavailable
          name = data.engress.interfaceName
        }
      }
    }
  }

  #if DEBUG
    #Preview {
      BindingPreviewable(AnyProxy()) { $data in
        ProxyEditorNICEditingSheet(data: $data)
      }
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    #Preview {
      @Previewable @State var data = AnyProxy()
      ProxyEditorNICEditingSheet(data: $data)
    }
  #endif
#endif
