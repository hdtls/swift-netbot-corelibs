//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct SecureDNSSettings: View {
  @Bindable var data: Profile.PersistentModel
  @State private var serverAddress = ""

  var body: some View {
    Section {
      TextField(
        "Encrypted DNS",
        text: $serverAddress,
        prompt: Text("DNS Server URL or Name")
      )
      .labelsHidden()
      .onSubmit {
        data.dnsSettings.serverURLString = serverAddress
      }
    } header: {
      Text("Encrypted DNS")
    } footer: {
      Group {
        Text(
          "If encrypted DNS is configured, the traditional DNS will only be used to test the connectivity and resolve the domain in the encrypted DNS URL."
        )
        .padding(.bottom, 8)
        Text(
          """
          Supported Protocol:
          • DNS over TLS
          • DNS over HTTPS
          • DNS over QUIC
          """
        )
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
      #if os(macOS)
        .frame(width: 350, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
      #endif
    }
  }
}

#if DEBUG
  #Preview {
    PersistentStorePreviewable<Profile.PersistentModel> { models in
      Form {
        SecureDNSSettings(data: models.first.unsafelyUnwrapped)
      }
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @Query var models: [Profile.PersistentModel]
    Form {
      SecureDNSSettings(data: models.first.unsafelyUnwrapped)
    }
  }
#endif
