//
// See LICENSE.txt for license information
//

import Foundation
import Netbot
import SwiftData
import SwiftUI

struct GeneralSettings: View {

  typealias Data = Profile.PersistentModel

  @AppStorage(Prefs.Name.profileURL, store: .applicationGroup) private var profileURL = URL.profile

  @AppStorage(Prefs.Name.maxminddbDownloadURL, store: .applicationGroup)
  private var maxminddbDownloadURL = URL(string: "https://git.io/GeoLite2-Country.mmdb")!

  @AppStorage(Prefs.Name.maxminddbKeepUpToDate, store: .applicationGroup)
  private var maxminddbKeepUpToDate = true

  @AppStorage(Prefs.Name.maxminddbLastUpdatedDate, store: .applicationGroup)
  private var maxminddbLastUpdatedDate = Date(timeIntervalSinceReferenceDate: 0)

  @Environment(\.profileAssistant) private var profileAssistant
  @Environment(\.session) private var session

  @Query(sort: \Data.creationDate) private var profiles: [Data]

  @State private var presentingAdvancedProxyServiceSettings: Bool = false
  @State private var downloadProgressIsFinished = true

  #if os(iOS)
    var body: some View {
      Form {
        Section {
          TextField("Custom Database URL", value: $maxminddbDownloadURL, format: ._url)

          Toggle("Automatic Updates", isOn: $maxminddbKeepUpToDate)

          Button {
            performMaxMindDBUpgrade()
          } label: {
            Text("Update Now")
          }
        } header: {
          Text("Geo Database")
        } footer: {
          Text("Last Updated: \(maxminddbLastUpdatedDate.formatted())")
        }
      }
      .navigationTitle("General")
    }
  #else
    var body: some View {
      @Bindable var profile = profiles.first ?? .init()
      Form {
        Section {
          LabeledContent {
            OpenAtLoginButton()
          } label: {
            Text("Open at Login:")
          }
        }

        Section {
          LabeledContent {
            Toggle("Allow remote proxy access", isOn: $profile.dontAllowRemoteAccess.reverse)
              .disabled(profiles.isEmpty)
          } label: {
            Text("Proxy Service:")
          }
          Button("Advanced Proxy Service Settings") {
            presentingAdvancedProxyServiceSettings = true
          }
          .disabled(profiles.isEmpty)
          .sheet(isPresented: $presentingAdvancedProxyServiceSettings) {
            RAListenPortsEditingSheet(data: profile)
          }
        }

        Section {
          TextField(
            "Internet Test URL:",
            value: $profile.testURL,
            format: ._url,
            prompt: Text("URL with http scheme")
          )
          .disabled(profiles.isEmpty)
          TextField(
            "Proxy Test URL:",
            value: $profile.proxyTestURL,
            format: ._url,
            prompt: Text("URL with http scheme")
          )
          .disabled(profiles.isEmpty)
          TextField(
            "Test Timeout", value: $profile.testTimeout,
            format: .number,
            prompt: Text("Timeout time interval in seconds")
          )
          .disabled(profiles.isEmpty)
        }

        Section {
          Toggle(
            "Show error page for REJECT errors", isOn: $profile.dontAlertRejectErrors.reverse
          )
          .disabled(profiles.isEmpty)
        }

        Section {
          LabeledContent {
            HStack {
              Text("Last updated: \(maxminddbLastUpdatedDate.formatted())")

              Button("Update Now") {
                performMaxMindDBUpgrade()
              }
              .disabled(!downloadProgressIsFinished)

              Spacer()
            }
          } label: {
            Text("MaxMind Database:")
          }

          Text("\(ProcessInfo.processInfo.processName) uses GeoLite2 data created by MaxMind.")
            .font(.footnote)
            .foregroundColor(.secondary)

          TextField(
            "Download URL:",
            value: $maxminddbDownloadURL,
            format: ._url
          )
          .frame(maxWidth: .infinity)
          .labelsHidden()

          Toggle("Automatic updates GeoIP database weekly", isOn: $maxminddbKeepUpToDate)
        }
      }
      .frame(width: 450)
      .padding()
      .navigationTitle("General")
      .onChange(of: profile.dontAllowRemoteAccess) { _, newValue in
        Task(priority: .background) {
          try await profileAssistant.replace(\.dontAllowRemoteAccess, with: newValue)
        }
      }
      .onChange(of: profile.httpListenPort) { _, newValue in
        Task(priority: .background) {
          try await profileAssistant.replace(\.httpListenPort, with: newValue)
        }
      }
      .onChange(of: profile.socksListenPort) { _, newValue in
        Task(priority: .background) {
          try await profileAssistant.replace(\.socksListenPort, with: newValue)
        }
      }
      .onChange(of: profile.testURL) { _, newValue in
        Task(priority: .background) {
          try await profileAssistant.replace(\.testURL, with: newValue)
        }
      }
      .onChange(of: profile.proxyTestURL) { _, newValue in
        Task(priority: .background) {
          try await profileAssistant.replace(\.proxyTestURL, with: newValue)
        }
      }
      .onChange(of: profile.testTimeout) { _, newValue in
        Task(priority: .background) {
          try await profileAssistant.replace(\.testTimeout, with: newValue)
        }
      }
      .onChange(of: profile.dontAlertRejectErrors) { _, newValue in
        Task(priority: .background) {
          try await profileAssistant.replace(\.dontAlertRejectErrors, with: newValue)
        }
      }
    }
  #endif

  @MainActor private func performMaxMindDBUpgrade() {
    downloadProgressIsFinished = false
    //    let options: DownloadRequest.Options = [
    //      DownloadRequest.Options(rawValue: 1 << 0), DownloadRequest.Options(rawValue: 1 << 1),
    //    ]
    //    session.download(
    //      maxminddbDownloadURL,
    //      to: { temporaryDirectory, response in
    //        (
    //          URL.applicationSupportMaxMindDBDirectory.appending(path: "GeoLite2-Country.mmdb"),
    //          options
    //        )
    //      }
    //    )
    //    .response { response in
    //      Task { @MainActor in
    //        downloadProgressIsFinished = true
    //        guard response.value != nil else {
    //          return
    //        }
    //        maxminddbLastUpdatedDate = Date.now
    //      }
    //    }
  }
}

#if DEBUG
  #Preview {
    NavigationStack {
      PersistentStorePreviewable {
        GeneralSettings()
      }
    }
  }

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
  #Preview(traits: .persistentStore()) {
    GeneralSettings()
  }
#endif
