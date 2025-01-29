//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ProxyEditorTSGroup: View {
  @Binding var data: AnyProxy
  @State private var presentingFileImporter = false

  #if os(iOS)
    var body: some View {
      Section {
        Toggle("TLS", isOn: $data.tls.isEnabled)

        if data.tls.isEnabled {
          Toggle(
            "Skip Server Certificate Verification",
            isOn: $data.tls.skipCertificateVerification
          )

          HStack {
            Text("SNI")
            TextField("SNI", text: $data.tls.sni, prompt: Text("Optional"))
              .multilineTextAlignment(.trailing)
          }

          HStack {
            Text("Certificate Pinning")
            TextField("", text: $data.tls.certificatePinning)
              .multilineTextAlignment(.trailing)
          }
        }
      } header: {
        Text(verbatim: "Transport Security")
      }
    }
  #else
    var body: some View {
      GroupBox {
        VStack(alignment: .leading) {
          if data.kind == .vmess {
            Toggle("Enable TLS", isOn: $data.tls.isEnabled)
          }
          VStack(alignment: .leading) {
            Toggle(
              "Skip Server Certificate Verification",
              isOn: $data.tls.skipCertificateVerification
            )
            HStack {
              Text("Custom TLS SNI")
              TextField("", text: $data.tls.sni, prompt: Text("Optional"))
            }
            HStack {
              Text("Certificate Pinning")
              TextField(
                "", text: $data.tls.certificatePinning, prompt: Text("SHA256 Fingerprint"))
            }

            Divider()

            Text("Client Certificate Authentication")
            HStack {
              Text(
                data.tls.certificatePinning.isEmpty
                  ? "Not Configured" : "Configured"
              )

              Spacer(minLength: 16)

              if !data.tls.certificatePinning.isEmpty {
                Button {
                  self.data.tls.certificatePinning = ""
                } label: {
                  Text("Unload - \(data.tls.certificatePinning)")
                    .truncationMode(.middle)
                }
              } else {
                Button {
                  presentingFileImporter = true
                } label: {
                  Text("Open...")
                    .frame(width: 120)
                }
              }
            }
          }
          .disabled(data.kind == .vmess ? !data.tls.isEnabled : false)
          .padding(.leading, data.kind == .vmess ? 8 : 0)
        }
      } label: {
        Text(verbatim: "TLS")
      }
      .fileImporter(
        isPresented: $presentingFileImporter,
        allowedContentTypes: [.x509Certificate, .pkcs12]
      ) { result in
        switch result {
        case .success(let url):
          data.tls.certificatePinning = url.lastPathComponent
        case .failure(let error):
          assertionFailure(error.localizedDescription)
        }
      }
    }
  #endif
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxy()
    ProxyEditorTSGroup(data: $data)
  }
#endif
