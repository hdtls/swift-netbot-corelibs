//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

struct CleartextDNSSettings: View {
  @AppStorage(Prefs.Name.dns) private var cleartextDnsServerType: CleartextDnsServerType = .system
  @Bindable var data: Profile.PersistentModel
  @Environment(\.profileAssistant) private var profileAssistant
  @State private var dnsServersString = ""
  #if os(iOS)
    @State private var presentingDnsServerEditor = false
  #endif

  var body: some View {
    Section("DNS Server") {
      VStack(alignment: .leading) {
        Picker(selection: $cleartextDnsServerType) {
          ForEach(CleartextDnsServerType.allCases, id: \.self) {
            Text($0.localizedName)
          }
        }
        #if os(iOS)
          .pickerStyle(.inline)
        #else
          .pickerStyle(.radioGroup)
        #endif
        .labelsHidden()

        #if os(macOS)
          TextField(
            "Custom DNS Server Addresses",
            text: $dnsServersString,
            prompt: Text("Custom DNS Server Addresses") + Text("(Separated by Commas)")
          )
          .onSubmit {
            let servers =
              dnsServersString
              .split(separator: ",")
              .map { $0.trimmingCharacters(in: .whitespaces) }
              .filter { $0.isIPAddress() }

            Task(priority: .background) {
              try await profileAssistant.replace(\.dnsSettings.servers, with: servers)
            }
            data.dnsSettings.servers = servers
          }
          .labelsHidden()
          .onAppear {
            dnsServersString = data.dnsSettings.servers.joined(separator: ",")
          }
        #endif
      }
    }

    #if os(iOS)
      if cleartextDnsServerType != .system {
        Section {
          ForEach(data.dnsSettings.servers, id: \.self) { address in
            HStack {
              Button {
                withAnimation {
                  Task(priority: .background) {
                    try await profileAssistant.removeDNSServer(address)
                  }
                  data.dnsSettings.servers.removeAll(where: { $0 == address })
                }
              } label: {
                Image(systemName: "minus")
                  .symbolVariant(.circle.fill)
                  .foregroundColor(.red)
              }
              Text(address)
            }
          }
          .onDelete { offsets in
            Task(priority: .background) {
              try await profileAssistant.removeDNSServers(atOffsets: offsets)
            }
            for offset in offsets {
              data.dnsSettings.servers.remove(at: offset)
            }
          }

          Button {
            presentingDnsServerEditor = true
          } label: {
            HStack {
              Image(systemName: "plus")
                .symbolVariant(.circle.fill)
                .foregroundColor(.green)
              Text("New \(Text(verbatim: "DNS"))") + Text("Server Address")
            }
          }
          .sheet(isPresented: $presentingDnsServerEditor) {
            List {
              Section {
                TextField(text: $dnsServersString) {
                  Text("DNS Server Address")
                }
              }
            }
            .toolbar {
              ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", role: .cancel) {
                  presentingDnsServerEditor = false
                  dnsServersString = ""
                }
              }

              ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                  presentingDnsServerEditor = false
                  data.dnsSettings.servers.append(dnsServersString)
                  let newValue = data.dnsSettings.servers
                  Task(priority: .background) {
                    try await profileAssistant.replace(\.dnsSettings.servers, with: newValue)
                  }
                }
              }
            }
            .navigationTitle(Text("New \(Text("DNS Server"))"))
          }

        } header: {
          Text("Custom DNS Server Addresses")
        }
      }
    #endif
  }
}

extension CleartextDnsServerType {

  fileprivate var localizedName: String {
    switch self {
    case .system:
      return String(localized: "Use system DNS servers")
    case .custom:
      return String(localized: "Use custom DNS servers")
    case .mixed:
      return String(localized: "Use system and custom DNS servers")
    }
  }
}

#if DEBUG
  #Preview {
    PersistentStorePreviewable<Profile.PersistentModel> { models in
      Form {
        CleartextDNSSettings(data: models.first.unsafelyUnwrapped)
      }
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    @Previewable @Query var models: [Profile.PersistentModel]
    Form {
      CleartextDNSSettings(data: models.first.unsafelyUnwrapped)
    }
  }
#endif
