//
// See LICENSE.txt for license information
//

#if os(iOS)
  import Netbot
  import SwiftData
  import SwiftUI
  import UniformTypeIdentifiers

  struct ProfileSettings: View {

    typealias Data = Profile.PersistentModel

    @AppStorage(Prefs.Name.profileURL, store: .applicationGroup)
    private var profileURL = URL.profile

    @AppStorage(Prefs.Name.automaticallyReloadProfile)
    private var automaticallyReloadProfile = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var profiles: [Data]
    @State private var file = ""
    @State private var selection: Data.ID?
    @State private var presentingProfileExporter = false
    @State private var presentingProfileEditor = false
    @State private var presentingImportProfileFromFileSharingAlert = false
    @State private var allowedContentTypes: [UTType] = []
    @State private var presentingProfileImporter = false
    @State private var presentingProfileDownloadURLEditingSheet = false
    @State private var profileName = ""
    @State private var profileDownloadURL: URL?
    @State private var presenting: Data?
    @State private var alert = Alert(kind: .create, isPresented: false)

    /// In used Profile.
    private var profile: Data? {
      profiles.first { $0.url == profileURL }
    }

    private var isDeletable: Bool {
      // *DO NOT* delete Profile whitch is in use.
      selection != nil && selection != profile?.persistentModelID
    }

    init<Value>(
      filter: Predicate<Data>? = nil, sort keyPath: KeyPath<Data, Value> = \.creationDate,
      order: SortOrder = .forward
    ) where Value: Comparable {
      _profiles = Query(filter: filter, sort: keyPath, order: order)
    }

    var body: some View {
      List {
        Section {
          ForEach(profiles) { profile in
            Button {
              profileURL = profile.url
            } label: {
              HStack {
                VStack(alignment: .leading) {
                  Text(profile.name)
                    .foregroundColor(.primary)

                  Text(
                    "Last Modified: \(profile.contentModificationDate.formatted())"
                  )
                  .font(.caption)
                  .foregroundColor(.secondary)
                }

                if profileURL == profile.url {
                  Spacer()

                  Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                }
              }
            }
          }
        } header: {
          Text("Profiles")
            .textCase(.uppercase)
        }
      }
      .navigationTitle("Profile")
      .toolbar {
        Menu {
          Section("Edit") {
            Button {
              presentingProfileEditor = true
            } label: {
              Label(
                "Edit \(profileName) in Text Mode",
                systemImage: "square.and.pencil"
              )
            }
          }

          Section("Import") {
            Button("Install from URL...") {
              presentingProfileDownloadURLEditingSheet = true
            }

            Button {
              presentingImportProfileFromFileSharingAlert = true
            } label: {
              Label("Copy via iTunes File Sharing", systemImage: "doc.on.doc")
            }

            Button("Import...") {
              allowedContentTypes = [.profile]
              presentingProfileImporter = true
            }
          }

          Section("Export") {
            if let profile {
              ShareLink(item: Profile(persistentModel: profile), preview: .init(""))
              Button {
                presentingProfileExporter = true
              } label: {
                Label(
                  "Export to iCloud or Other Apps",
                  systemImage: "square.and.arrow.up.on.square"
                )
              }
            }
          }
          .disabled(profile == nil)
        } label: {
          Image(systemName: "ellipsis")
            .symbolVariant(.circle)
        }
      }
      .sheet(isPresented: $presentingProfileEditor) {
        NavigationStack {
          TextEditor(text: $file)
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                  presentingProfileEditor = false
                } label: {
                  Text("Cancel")
                }
              }

              ToolbarItem(placement: .confirmationAction) {
                Button {
                  presentingProfileEditor = false
                } label: {
                  Text("Done")
                }
              }
            }
        }
      }
      .alert(
        "Copy via iTunes File Sharing",
        isPresented: $presentingImportProfileFromFileSharingAlert,
        actions: {
          Button("OK") {
            presentingImportProfileFromFileSharingAlert = false
          }
        },
        message: {
          Text(
            "You can copy profile file via iTunes file sharing. Filename should end with .\(UTType.profile.preferredFilenameExtension ?? "")"
          )
        }
      )
    }
  }

  #if DEBUG
    #Preview {
      PersistentStorePreviewable {
        NavigationStack {
          ProfileSettings()
        }
      }
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    #Preview(traits: .persistentStore()) {
      NavigationStack {
        ProfileSettings()
      }
    }
  #endif
#endif
