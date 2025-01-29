//
// See LICENSE.txt for license information
//

import Netbot
import SwiftUI

struct ProxyEditorCredentialGroup: View {
  @Binding var data: AnyProxy
  private var authenticationSectionTitle: LocalizedStringKey {
    switch data.kind {
    case .shadowsocks: return "Shadowsocks"
    case .vmess: return "VMESS"
    case .http, .https, .socks5, .socks5OverTLS: return "Credential"
    case .direct, .reject, .rejectTinyGIF: return ""
    }
  }

  #if os(iOS)
    var body: some View {
      Section {
        switch data.kind {
        case .shadowsocks:
          Picker("Algorithm", selection: $data.algorithm) {
            ForEach(Algorithm.allCases, id: \.self) {
              Text($0.rawValue)
            }
          }
          passwordField
        case .vmess:
          HStack {
            Text("ID")
            TextField(
              "ID",
              value: $data.username,
              formatter: UUID.Formatter()
            )
            .multilineTextAlignment(.trailing)
          }
        case .http, .https, .socks5, .socks5OverTLS:
          Toggle("Authentication Required", isOn: $data.authenticationRequired)
          if data.authenticationRequired {
            userNameField
            passwordField
          }
        default:
          EmptyView()
        }
      } header: {
        Text(authenticationSectionTitle)
      }
    }

    private var userNameField: some View {
      HStack {
        Text("Username")
        TextField("Username", text: $data.username)
          .multilineTextAlignment(.trailing)
      }
    }

    private var passwordField: some View {
      HStack {
        Text("Password")
        SecureField("Password", text: $data.passwordReference)
          .multilineTextAlignment(.trailing)
      }
    }
  #else
    var body: some View {
      switch data.kind {
      case .direct, .reject, .rejectTinyGIF:
        EmptyView()
      case .shadowsocks:
        GroupBox {
          VStack {
            Picker("Encryption Method", selection: $data.algorithm) {
              ForEach(Algorithm.allCases, id: \.self) {
                Text($0.rawValue)
              }
            }
            .accessibilityIdentifier("Encryption Method")
            SecureField("Password", text: $data.passwordReference, prompt: Text("Password"))
          }
        } label: {
          Text(authenticationSectionTitle)
            .accessibilityIdentifier("Credential")
        }
      case .http, .https, .socks5, .socks5OverTLS:
        GroupBox {
          VStack(alignment: .leading) {
            Toggle("Authentication Required", isOn: $data.authenticationRequired)
            Form {
              TextField("Username", text: $data.username, prompt: Text("Username"))
              SecureField("Password", text: $data.passwordReference, prompt: Text("Password"))
            }
            .disabled(!data.authenticationRequired)
            .padding(.leading)
          }
        } label: {
          Text(authenticationSectionTitle)
            .accessibilityIdentifier("Credential")
        }
      case .vmess:
        GroupBox {
          VStack(alignment: .leading) {
            TextField("ID", value: $data.username, formatter: UUID.Formatter())
              .accessibilityIdentifier("Username")
          }
        } label: {
          Text(authenticationSectionTitle)
            .accessibilityIdentifier("Credential")
        }
      }
    }
  #endif
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview {
    @Previewable @State var data = AnyProxy()
    ProxyEditorCredentialGroup(data: $data)
  }
#endif
