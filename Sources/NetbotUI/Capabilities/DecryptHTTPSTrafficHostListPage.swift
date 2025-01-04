//
// See LICENSE.txt for license information
//

#if os(iOS)
  import Netbot
  import SwiftData
  import SwiftUI

  struct DecryptHTTPSTrafficHostListPage: View {

    @Query private var profiles: [Profile.PersistentModel]
    @State private var presentingEditor = false
    @State private var textToAdd = ""

    init<Value>(
      filter: Predicate<Profile.PersistentModel>? = nil,
      sort keyPath: KeyPath<Profile.PersistentModel, Value> = \.creationDate
    ) where Value: Comparable {
      _profiles = Query(filter: filter, sort: keyPath)
    }

    var body: some View {
      List {
        Section {
          ForEach(profiles.first?.hostnames ?? [], id: \.self) {
            Text($0)
          }
          .onDelete { offsets in
            profiles.first?.hostnames.remove(atOffsets: offsets)
            // TODO: ALSO UPDATE PROFILE FILE CONTENTS
          }
        } header: {
          Text("Allow MitM Hostnames")
        } footer: {
          VStack(alignment: .leading) {
            Text(
              """
              Netbot will only decrypt traffic to the hosts whitch are declared and enabled here."

              Some applications has a strict security policy to use pinned certificates or CA. Enabling decryption to these hosts may cause problems.
              """
            )
          }
        }
      }
      .navigationTitle("MitM Hostnames")
      .toolbar {
        Button {
          presentingEditor = true
        } label: {
          Image(systemName: "plus")
        }
      }
      .sheet(isPresented: $presentingEditor) {
        textToAdd = ""
      } content: {
        NavigationStack {
          List {
            Section {
              TextField("", text: .constant("*.example.com"))
            } footer: {
              VStack(alignment: .leading) {
                Text(
                  """
                  Wildcard characters * and ? are supported.
                  Use prefix - to exclude a hostname.
                  By default only the requests to port 443 will be decrypted.
                  • Use suffix :port to allow other ports.
                  • Use suffix :0 to allow all ports.
                  See manual for more information.
                  """
                )
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom)
              }
            }
          }
          .navigationTitle("New MitM Hostname")
          .toolbar {
            toolbarItems
          }
        }
      }
    }

    @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel", role: .cancel) {
          presentingEditor = false
        }
      }

      ToolbarItem(placement: .confirmationAction) {
        Button("Done") {
          if !textToAdd.trimmingCharacters(in: .whitespaces).isEmpty {
            profiles.first?.hostnames.append(textToAdd)
            // TODO: ALSO UPDATE PROFILE FILE CONTENTS
          }
          presentingEditor = false
        }
      }
    }
  }
#endif
