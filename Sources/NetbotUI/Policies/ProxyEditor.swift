//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct ProxyEditor: View {
  @Binding var data: AnyProxy
  @State private var presentingFileImporter = false
  private var disabled = false

  private init(data: Binding<AnyProxy>, disabled: Bool) {
    self._data = data
    self.disabled = disabled
  }

  init(data: Binding<AnyProxy>) {
    self._data = data
  }

  #if os(iOS)
    var body: some View {
      Form {
        Group {
          ProxyEditorNamingGroup(data: $data)

          if data.kind.isProxyable {
            ProxyEditorSVRIGroup(data: $data)
            ProxyEditorCredentialGroup(data: $data)
            if data.kind.supportTLSSettings {
              ProxyEditorTSGroup(data: $data)
            }
            if data.kind == .shadowsocks {
              ProxyEditorOBFSGroup(data: $data)
            }
            if data.kind == .vmess {
              ProxyEditorWSGroup(data: $data)
            }

            ProxyEditorDiagnosisGroup(data: $data)

            ProxyEditorEgressControlGroup(data: $data)

            ProxyEditorOptionsGroup(data: $data)
          }
        }
        .disabled(disabled)
      }
    }

    func disabled(_ disabled: Bool) -> ProxyEditor {
      ProxyEditor(data: $data, disabled: disabled)
    }
  #else
    var body: some View {
      VStack {
        ProxyEditorNamingGroup(data: $data)

        HStack(alignment: .top) {
          Group {
            VStack(alignment: .leading) {
              ProxyEditorSVRIGroup(data: $data)
              ProxyEditorCredentialGroup(data: $data)
              if data.kind.supportTLSSettings {
                ProxyEditorTSGroup(data: $data)
              }

              switch data.kind {
              case .http, .socks5:
                ProxyEditorDiagnosisGroup(data: $data)
              case .shadowsocks:
                ProxyEditorOBFSGroup(data: $data)
              case .vmess:
                ProxyEditorWSGroup(data: $data)
              default:
                EmptyView()
              }
            }

            VStack(alignment: .leading) {
              switch data.kind {
              case .https, .shadowsocks, .socks5OverTLS, .vmess:
                ProxyEditorDiagnosisGroup(data: $data)
              default:
                EmptyView()
              }
              ProxyEditorEgressControlGroup(data: $data)
            }

            VStack(alignment: .leading) {
              ProxyEditorOptionsGroup(data: $data)
            }
          }
          .frame(width: 280)
        }
      }
      .padding(.horizontal, 32)
      .padding(.vertical)
    }
  #endif
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @State var data = AnyProxy()
    NavigationStack {
      ProxyEditor(data: $data)
    }
  }
#endif
