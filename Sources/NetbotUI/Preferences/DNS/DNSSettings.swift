//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct DNSSettings: View {

  @Query private var profiles: [Profile.PersistentModel]

  #if os(iOS)
    var body: some View {
      if let profile = profiles.first {
        Form {
          CleartextDNSSettings(data: profile)

          SecureDNSSettings(data: profile)

          #if EXTENDED_ALL
            PrivateDNSSettings()
          #endif

          DNSOptionsSettings()
        }
        .navigationTitle(Text(verbatim: "DNS"))
      } else {
        ContentUnavailableView("No Selected Profile", systemImage: "exclamationmark")
          .symbolVariant(.circle)
      }
    }
  #else
    var body: some View {
      Form {
        HStack(alignment: .top) {
          VStack(alignment: .leading) {
            CleartextDNSSettings(data: profiles.first ?? .init())

            VStack(alignment: .leading) {
              SecureDNSSettings(data: profiles.first ?? .init())
            }
            .padding(.top)
          }
          Divider()
          VStack(alignment: .leading) {
            DNSOptionsSettings()

            #if EXTENDED_ALL
              VStack(alignment: .leading) {
                PrivateDNSSettings()
              }
              .padding(.top)
            #endif
          }
        }
        Divider()
          .padding(.bottom)

        LocalDNSMappingSettings()
      }
      .padding()
      .fixedSize()
      .disabled(profiles.isEmpty)
    }
  #endif
}

#if DEBUG
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    NavigationStack {
      DNSSettings()
    }
  }
#endif
