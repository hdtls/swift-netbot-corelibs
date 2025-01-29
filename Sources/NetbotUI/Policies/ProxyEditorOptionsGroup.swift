//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ProxyEditorOptionsGroup: View {
  @Binding var data: AnyProxy

  #if os(iOS)
    var body: some View {
      Section {
        Toggle("TCP Fast Open (Experimental)", isOn: $data.isTFOEnabled)
        switch data.kind {
        case .http, .https:
          Toggle(
            "Always use HTTP CONNECT method", isOn: $data.forceHTTPTunneling)
        case .socks5, .socks5OverTLS, .shadowsocks:
          Toggle("Allow UDP Relay", isOn: $data.allowUDPRelay)
        case .vmess:
          //            Toggle("VMESS AEAD", isOn: $data.prefererHttpTunneling)
          EmptyView()
        default:
          EmptyView()
        }
      } header: {
        Text("Options")
          .textCase(.uppercase)
      } footer: {
        switch data.kind {
        case .http, .https:
          Text("Always use HTTP CONNECT method for relay, even for plain requests.")
            .font(.footnote)
            .foregroundColor(.secondary)
        case .socks5, .socks5OverTLS, .shadowsocks:
          Text("Forward UDP packets to the proxy server if enhenced mode is enabled.")
            .font(.footnote)
            .foregroundColor(.secondary)
        default:
          EmptyView()
        }
      }
      Section {
        Toggle("Don't Alert Errors", isOn: $data.dontAlertError)
      } footer: {
        Text("Suppress error alerts while encountering errors.")
          .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
  #else
    var body: some View {
      GroupBox {
        VStack(alignment: .leading) {
          switch data.kind {
          case .http, .https:
            Toggle(
              "Always use HTTP CONNECT method", isOn: $data.forceHTTPTunneling)
            Text("Always use HTTP CONNECT method for relay, even for plain requests.")
              .font(.footnote)
              .foregroundColor(.secondary)
              .padding(.leading, 18)
              .frame(maxWidth: .infinity, alignment: .leading)
              .fixedSize(horizontal: false, vertical: true)
          case .socks5, .socks5OverTLS, .shadowsocks, .vmess:
            if data.kind == .vmess {
              //                Toggle("VMESS AEAD", isOn: $data.proxySettings.prefererHttpTunneling)
            } else {
              Toggle("Allow UDP Relay", isOn: $data.allowUDPRelay)
              Text("Forward UDP packets to the proxy server if enhenced mode is enabled.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.leading, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }

            Toggle(
              "TCP Fast Open (Experimental)", isOn: $data.isTFOEnabled)
          default:
            EmptyView()
          }

          Toggle("Don't Alert Errors", isOn: $data.dontAlertError)
          Text("Suppress error alerts while encountering errors.")
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.leading, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
      } label: {
        Text("Options")
      }
    }
  #endif
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxy()
    ProxyEditorOptionsGroup(data: $data)
  }
#endif
