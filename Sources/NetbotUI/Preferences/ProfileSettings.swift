//
// See LICENSE.txt for license information
//

#if os(macOS)
  import Netbot
  import NetbotUI
  import SwiftData
  import SwiftUI
  import UniformTypeIdentifiers

  struct ProfileSettings: View {

    @AppStorage(Prefs.Name.profileURL, store: .applicationGroup)
    private var profileURL = URL.profile

    @AppStorage(Prefs.Name.profilesDirectory)
    private var profilesDirectory = URL.profile.deletingLastPathComponent()

    @AppStorage(Prefs.Name.profileAutoreload)
    private var profileAutoreload = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.profileAssistant) private var profileAssistant

    @ObservedObject private var profileResource = ProfileAssistant.shared.profileResource

    @State private var textSize: CGSize = .zero
    @State private var selectedProfileUniqueID: ProfileInfo.ID?
    @State private var presentingExporter = false
    @State private var allowedContentTypes: [UTType] = []
    @State private var presentingImporter = false
    @State private var presentingURLEditingSheet = false
    @State private var profileDownloadURL: URL?
    @State private var profileName = ""
    @State private var presenting: URL?
    @State private var document: Profile?
    @State private var alert = Alert(kind: .create, isPresented: false)
    @State private var sortOrder = [KeyPathComparator(\ProfileInfo.name)]

    var body: some View {
      VStack {
        VStack(alignment: .leading) {
          HStack(spacing: 8) {
            Text("Profile Path:")
              .onSizeChange { size in
                Task { @MainActor in
                  textSize = size
                }
              }

            PathControl(url: $profilesDirectory) { _ in }
          }
          .padding(.bottom, 4)

          Group {
            Text("Specify a folder to store profile files.")
              .font(.footnote)

            HStack {
              Button("Reveal Profiles in Finder") {
                openURL(profileURL)
              }

              Button("Change Profile Folder...") {
                allowedContentTypes = [.directory, .folder]
                presentingImporter = true
              }
            }

            Toggle(
              "Automatically reload if the profile was modified externally or remotely",
              isOn: $profileAutoreload
            )
          }
          .padding(.leading, textSize.width)
        }

        Table(profileResource.profiles, selection: $selectedProfileUniqueID, sortOrder: $sortOrder)
        {
          TableColumn("") {
            if $0.url == profileURL {
              Image(systemName: "checkmark")
            }
          }
          .width(12)
          TableColumn("Name", value: \.url.suggestedFilename)
          TableColumn("Description") {
            Text("\($0.numberOfRules) Proxy Rules, \($0.numberOfProxies) Proxies")
          }
        }
        .contextMenu(forSelectionType: ProfileInfo.ID.self) {
          if let activeURL = $0.first {
            Section {
              Button("Rename") {
                presenting = activeURL
                profileName = activeURL.suggestedFilename
                alert = .init(kind: .rename)
              }

              Button("Duplicate") {
                duplicate(activeURL)
              }
            }

            Section {
              Button("Export...") {
                presenting = activeURL
                presentingExporter = true
              }
            }

            if activeURL != profileURL {
              Section {
                Button("Delete...", role: .destructive) {
                  presenting = activeURL
                  alert = .init(kind: .delete)
                }
              }
            }
          }
        } primaryAction: {
          guard let activeURL = $0.first else {
            return
          }
          // Double click to switch profile.
          profileURL = activeURL
        }
        .onDeleteCommand {
          // Delete selected profile when system delete command trigged if possible.
          guard let selectedProfileUniqueID else { return }
          presenting = selectedProfileUniqueID
          alert = .init(kind: .delete)
        }
        .onChange(of: sortOrder) { _, sortOrder in
          profileResource.profiles.sort(using: sortOrder)
        }
        .frame(height: 200)

        HStack {
          Menu("New Profile") {
            Button("New Empty Profile") {
              profileName = "New Empty Profile"
              presenting = nil
              alert = .init(kind: .create)
            }

            Button("Duplicate Selected Profile") {
              guard let selectedProfileUniqueID else { return }
              duplicate(selectedProfileUniqueID)
            }
            .disabled(selectedProfileUniqueID == nil)
          }
          .menuIndicator(.hidden)
          .fixedSize()

          Button("Export...") {
            presenting = selectedProfileUniqueID
            presentingExporter = true
          }
          .disabled(selectedProfileUniqueID == nil)

          Button("Delete...", role: .destructive) {
            presenting = selectedProfileUniqueID
            alert = .init(kind: .delete)
          }
          .disabled(selectedProfileUniqueID == nil || selectedProfileUniqueID == profileURL)

          Button("Rename...") {
            presenting = selectedProfileUniqueID
            profileName = selectedProfileUniqueID?.suggestedFilename ?? ""
            alert = .init(kind: .rename)
          }
          .disabled(selectedProfileUniqueID == nil)

          Button("Import...") {
            allowedContentTypes = [.profile]
            presentingImporter = true
          }

          Button("Install from URL...") {
            presentingURLEditingSheet = true
          }
        }
      }
      .padding()
      .fixedSize()
      .fileImporter(
        isPresented: $presentingImporter,
        allowedContentTypes: allowedContentTypes,
        onCompletion: pickURL
      )
      .fileExporter(
        isPresented: $presentingExporter,
        document: ProfileDocument(contentsOf: presenting),
        onCompletion: exportProfile
      )
      .fileDialogDefaultDirectory(profileURL.deletingLastPathComponent())
      .alert(alert.title, isPresented: $alert.isPresented, presenting: presenting) { presenting in
        Button("Cancel", role: .cancel) {
          alert.isPresented = false
          self.presenting = nil
        }
        switch alert.kind {
        case .create:
          Button("OK") {
            makeProfile(nil, name: profileName)
            alert.isPresented = false
            self.presenting = nil
          }
          .disabled(profileName.isEmpty)
          TextField("", text: $profileName)
            .labelsHidden()
        case .rename:
          Button("Rename") {
            rename(presenting, to: profileName)
            alert.isPresented = false
            self.presenting = nil
          }
          .disabled(profileName.isEmpty || profileName == presenting.suggestedFilename)
          TextField("", text: $profileName)
            .labelsHidden()
        case .delete:
          Button("Delete", role: .destructive) {
            delete(presenting)
            alert.isPresented = false
            self.presenting = nil
          }
        }
      } message: { presenting in
        alert.message(presenting)
      }
      .sheet(
        isPresented: $presentingURLEditingSheet,
        onDismiss: {
          profileDownloadURL = nil
        },
        content: {
          NavigationStack {
            TextField("", value: $profileDownloadURL, format: ._url)
              .frame(width: 350)
              .padding()
              .navigationTitle("Install Profile from URL")
              .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                  Button("Cancel", role: .cancel) {
                    presentingURLEditingSheet = false
                  }
                }
                ToolbarItem(placement: .confirmationAction) {
                  Button("Done") {
                    if let profileDownloadURL {
                      downloadProfile(from: profileDownloadURL)
                    }
                  }
                  .disabled(profileDownloadURL == nil)
                }
              }
          }
        }
      )
    }
  }

  extension ProfileSettings {

    private func pickURL(_ result: Result<URL, any Error>) {
      guard case .success(let url) = result, url.startAccessingSecurityScopedResource() else {
        return
      }
      // When the url is a directory, select the profiles folder,
      // otherwise the profile file will be imported.
      if url.isDirectory {
        profilesDirectory = url
      } else {
        profileName = url.suggestedFilename
        makeProfile(url, name: profileName)
      }
      url.stopAccessingSecurityScopedResource()
    }

    private func exportProfile(_ result: Result<URL, any Error>) {
      guard case .success(let url) = result, url.startAccessingSecurityScopedResource() else {
        return
      }
      url.stopAccessingSecurityScopedResource()
    }

    private func downloadProfile(from url: URL) {

    }

    private func makeProfile(_ srcURL: URL?, name profileName: String) {
      Task {
        var profile = Profile()
        if let srcURL {
          profile = try await profileAssistant.profile(identified: srcURL)
        }
        profile.url = profileURL.deletingLastPathComponent().appendingPathComponent(
          profileName, conformingTo: .profile)
        try await profileAssistant.insert(profile)
      }
    }

    private func delete(_ url: URL) {
      Task {
        // The deletion operation is based on the file url and has nothing to do
        // with other properties, so we can create a template profile instead.
        var profile = Profile()
        profile.url = url
        try await profileAssistant.delete(profile)

        // Profile has been removed, release selection state if needed.
        if url == selectedProfileUniqueID {
          selectedProfileUniqueID = nil
        }
      }
    }

    private func rename(_ srcURL: URL, to profileName: String) {
      var dstURL = srcURL.deletingLastPathComponent()
      dstURL = dstURL.appendingPathComponent(profileName, conformingTo: .profile)

      Task {
        try await profileAssistant.moveProfile(fromURL: srcURL, to: dstURL)

        // Change selection state if needed.
        if srcURL == selectedProfileUniqueID {
          selectedProfileUniqueID = dstURL
        }
      }
    }

    private func duplicate(_ srcURL: URL) {
      let profileName = profileResource.profiles.map { $0.name }.duplicate(srcURL.suggestedFilename)
      makeProfile(srcURL, name: profileName)
    }
  }

  #if DEBUG
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    #Preview(traits: .persistentStore()) {
      NavigationStack {
        ProfileSettings()
      }
    }
  #endif
#endif
