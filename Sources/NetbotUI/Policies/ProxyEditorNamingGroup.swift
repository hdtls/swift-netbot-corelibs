//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ProxyEditorNamingGroup: View {
  @Binding var data: AnyProxy

  var body: some View {
    #if os(iOS)
      Section {
        textField
        picker
      } header: {
        Text("General")
      }
    #else
      HStack {
        textField
        picker
      }
      .padding(.bottom)
    #endif
  }

  private var textField: some View {
    HStack {
      Text("Name")
      TextField("Name", text: $data.name, prompt: Text("Proxy Name"))
        .labelsHidden()
        #if os(iOS)
          .multilineTextAlignment(.trailing)
        #endif
    }
  }

  private var picker: some View {
    Picker("Protocol", selection: $data.kind) {
      Section {
        Text(AnyProxy.Kind.http.localizedName)
          .tag(AnyProxy.Kind.http)
        Text(AnyProxy.Kind.https.localizedName)
          .tag(AnyProxy.Kind.https)
      }
      Section {
        Text(AnyProxy.Kind.socks5.localizedName)
          .tag(AnyProxy.Kind.socks5)
        Text(AnyProxy.Kind.socks5OverTLS.localizedName)
          .tag(AnyProxy.Kind.socks5OverTLS)
      }
      Section {
        Text(AnyProxy.Kind.shadowsocks.localizedName)
          .tag(AnyProxy.Kind.shadowsocks)
      }
      Section {
        Text(AnyProxy.Kind.vmess.localizedName)
          .tag(AnyProxy.Kind.vmess)
      }
    }
  }
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxy()
    ProxyEditorNamingGroup(data: $data)
  }
#endif
