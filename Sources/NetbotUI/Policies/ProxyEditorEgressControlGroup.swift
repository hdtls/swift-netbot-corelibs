//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ProxyEditorEgressControlGroup: View {
  @Binding var data: AnyProxy
  @State private var presentingInterfaceEditor = false

  #if os(iOS)
    var body: some View {
      Section {
        Picker(selection: $data.engress.versionStrategy) {
          ForEach(AnyProxy.Engress.VersionStrategy.allCases, id: \.self) {
            Text($0.rawValue)
          }
        } label: {
          Text("IP Version")
        }
      } header: {
        Text("Egress Control")
      } footer: {
        Text(
          "This option just affects the connections to the proxy server. Therefor it only makes sense when the proxy server's hostname is a domain. If the underlying proxy is configured, this option has no effect since the DNS resolution happens remotely."
        )
        .font(.footnote)
        .foregroundColor(.secondary)
      }
    }
  #else
    var body: some View {
      GroupBox {
        VStack(alignment: .leading) {
          Button("Bind Network Interface...") {
            presentingInterfaceEditor = true
          }
          .sheet(isPresented: $presentingInterfaceEditor) {
            ProxyEditorNICEditingSheet(data: $data)
          }
          Text(
            "You may force requests to go through the specific network interface. A secondary NIC or a VPN service."
          )
          .font(.footnote)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)

          Divider()

          HStack {
            Text("IP ToS")
            TextField(
              "IP ToS",
              value: $data.engress.packetToS,
              format: .number.grouping(.never),
              prompt: Text("IP ToS")
            )
            .labelsHidden()
          }

          Divider()

          Picker("IP Version", selection: $data.engress.versionStrategy) {
            ForEach(AnyProxy.Engress.VersionStrategy.allCases, id: \.self) {
              Text($0.rawValue)
                .tag($0)
            }
          }
          Text(
            "This option just affects the connections to the proxy server. Therefor it only makes sense when the proxy server's hostname is a domain. If the underlying proxy is configured, this option has no effect since the DNS resolution happens remotely."
          )
          .font(.footnote)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        }
      } label: {
        Text("Egress Control")
      }
    }
  #endif
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxy()
    ProxyEditorEgressControlGroup(data: $data)
  }
#endif
