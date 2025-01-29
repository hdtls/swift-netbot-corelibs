//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ProxyGroupEditorAutoURLTestNameGroup: View {
  @Binding var data: AnyProxyGroup

  var body: some View {
    VStack(alignment: .leading) {
      Form {
        TextField("Group Name", text: $data.name)
          .padding(.bottom)

        TextField(
          "Auto URL Test URL", value: $data.measurement.url, format: ._url,
          prompt: Text("Optional"))
        Text(
          "\(ProcessInfo.processInfo.processName) will send a HTTP HEAD request to the URL. The test only cares about whether receiving a response, even if the response is an HTTP error. HTTP (http://) only."
        )
        .foregroundStyle(.secondary)
        .font(.caption)
      }

      HStack(alignment: .top) {
        Form {
          TextField(
            "Expired", value: $data.measurement.transactionMetricsExpiryInterval,
            format: .number)
          Text(
            "The benchmark result will be discarded after the expired time. After that a re-test will happen."
          )
          .foregroundStyle(.secondary)
          .font(.caption)

          TextField("Timeout", value: $data.measurement.timeout, format: .number)
          Text("Abandon a policy if not finished test.")
            .foregroundStyle(.secondary)
            .font(.caption)
        }

        Divider()

        Form {
          TextField("Tolerance", value: $data.measurement.tolerance, format: .number)
          Text(
            "The selected policy will be changed only when the new winner has a higher score then the old one plus the tolerance."
          )
          .foregroundStyle(.secondary)
          .font(.caption)
        }
      }
    }
    .frame(maxWidth: 660)
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxyGroup()
    ProxyGroupEditorAutoURLTestNameGroup(data: $data)
  }
#endif
