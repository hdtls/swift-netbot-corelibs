//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ProxyEditorDiagnosisGroup: View {
  @Binding var data: AnyProxy

  #if os(iOS)
    var body: some View {
      Section {
        HStack {
          Text("URL")
          TextField(
            "",
            value: $data.measurement.url,
            format: ._url,
            prompt: Text("URL for Network Measurement")
          )
          .labelsHidden()
          .multilineTextAlignment(.trailing)
        }
      } header: {
        Text("Network Measurement")
      } footer: {
        Text("Override the global test URL for network measurement and activity cards.")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
  #else
    var body: some View {
      GroupBox {
        VStack(alignment: .leading) {
          TextField(
            "",
            value: $data.measurement.url,
            format: ._url,
            prompt: Text("URL for Network Measurement")
          )
          .labelsHidden()
          Text("Override the global proxy test URL for network diagnostics and activity cards.")
            .font(.footnote)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      } label: {
        Text("Network Measurement")
      }
    }
  #endif
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxy()
    ProxyEditorDiagnosisGroup(data: $data)
  }
#endif
