//
// See LICENSE.txt for license information
//

import Netbot
import SwiftData
import SwiftUI

private struct ProfileStatusSubscriptionModifier: ViewModifier {

  @AppStorage(Prefs.Name.logLevel, store: .applicationGroup)
  private var logLevel = Logger.Level.info

  @AppStorage(Prefs.Name.profileURL, store: .applicationGroup)
  private var profileURL = URL.profile

  @AppStorage(Prefs.Name.profilesDirectory)
  private var profilesDirectory = URL.profile.deletingLastPathComponent()

  @AppStorage(Prefs.Name.profileAutoreload)
  private var profileAutoreload = false

  @AppStorage(Prefs.Name.profileLastContentModificationDate, store: .applicationGroup)
  private var profileLastContentModificationDate = Date.now

  @Environment(\.profileAssistant) private var profileAssistant

  @Query private var profiles: [Profile.PersistentModel]

  private let session = Session.shared

  func body(content: Content) -> some View {
    content
      .task(id: profileURL) {
        await profileAssistant.setProfileURL(profileURL)
        await profileAssistant.reloadProfile()

        // Profile load failure, restore to virtual profile.
        if await profileAssistant.lastLoadError != nil {
          profileURL = await profileAssistant.virtualProfileURL
        }
      }
      .task(id: profileLastContentModificationDate) {
        await profileAssistant.setProfileURL(profileURL)
        await profileAssistant.reloadProfile()
      }
      .task(id: profilesDirectory) {
        await profileAssistant.setProfilesDirectory(profilesDirectory)
        await withDiscardingTaskGroup { g in
          g.addTask {
            await profileAssistant.reloadAllProfiles()
          }
          g.addTask {
            await profileAssistant.reloadProfile()

            if await profileAssistant.lastLoadError != nil {
              Task { @MainActor in
                profileURL = await profileAssistant.virtualProfileURL
              }
            }
          }
        }
      }
      .task(id: profileAutoreload) {
        await profileAssistant.setAutoreloadEnabled(profileAutoreload)
      }
      .task(id: profiles) {
        guard let profile = profiles.first else {
          return
        }
        if profile.logLevel != logLevel {
          logLevel = profile.logLevel
        }
        if let contentModificationDate = profile.url.contentModificationDate,
          contentModificationDate != profileLastContentModificationDate
        {
          profileLastContentModificationDate = contentModificationDate
        }
      }
      .task {
        do {
          try await session.startVPNTunnel(options: [:])
        } catch {
          session.logger.error("Session start failure with error: \(error)")
        }
      }
  }
}

extension View {
  public func subscribeToProfileStatus() -> some View {
    modifier(ProfileStatusSubscriptionModifier())
  }
}
