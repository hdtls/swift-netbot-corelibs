//
// See LICENSE.txt for license information
//

import Preference
import _PersistentStore

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import class Foundation.OperationQueue
#else
  import Foundation
#endif

@available(swift 5.9)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension ProfileAssistant {

  #if canImport(FoundationEssentials)
    typealias NSObject = AnyObject
  #endif

  /// FilePresenter used to observe changes in current active profiles directory.
  final class _FilePresenter: NSObject, NSFilePresenter, @unchecked Sendable {

    let presentedItemURL: URL?

    let presentedItemOperationQueue = OperationQueue()

    private let profileAssistant = ProfileAssistant.shared

    @Preference(Prefs.Name.profileURL, store: .applicationGroup)
    private var profileURL: URL = .profile

    @Preference(Prefs.Name.profileLastContentModificationDate, store: .applicationGroup)
    private var profileLastContentModificationDate = Date.now

    @Preference(Prefs.Name.profilesDirectory, store: .applicationGroup)
    private var profilesDirectory: URL = .profile.deletingLastPathComponent()

    /// Create FilePresenter with current active profiles directory.
    init(presentedItemURL: URL) {
      self.presentedItemURL = presentedItemURL
    }

    private var isValidURLScope: Bool {
      get async {
        let profilesDirectory = await profileAssistant.profilesDirectory
        let profileURL = await profileAssistant.profileURL

        guard presentedItemURL == profilesDirectory || presentedItemURL == profileURL else {
          return false
        }
        return true
      }
    }

    func accommodatePresentedItemDeletion() async throws {
      guard await isValidURLScope else {
        return
      }

      if await presentedItemURL == profileAssistant.profilesDirectory {
        // If entire profiles directory is removed, fallback to default profiles directory.
        profilesDirectory = URL.profile.deletingLastPathComponent()
      } else {
        // If current active profile is removed, fallback to virtual default profile, else ignored.
        profileURL = await profileAssistant.virtualProfileURL
      }
    }

    func presentedItemDidMove(to newURL: URL) {
      Task {
        guard await isValidURLScope else {
          return
        }

        let parent = presentedItemURL?.deletingLastPathComponent()

        if await presentedItemURL == profileAssistant.profilesDirectory {
          // If newURL and current active profiles directory has same parent, that means we have
          // renamed profiles folder, so we should update active profiles directory to the newURL.
          // else we should fallback to ues default profiles directory.
          guard newURL.deletingLastPathComponent() == parent else {
            profilesDirectory = .profile.deletingLastPathComponent()
            return
          }
          profilesDirectory = newURL
        } else {
          guard newURL.deletingLastPathComponent() == parent else {
            // Current active profile has been move to outside of the profiles directory, so we need
            // to reset active profile to virtual default.
            profileURL = await profileAssistant.virtualProfileURL
            await profileAssistant.reloadAllProfiles()
            return
          }

          // Because current active profile name is changed, so we need update profile url, and
          // also reload profiles.
          profileURL = newURL
          await profileAssistant.reloadAllProfiles()
        }
      }
    }

    func presentedItemDidChange() {
      Task {
        guard await isValidURLScope else {
          return
        }
        if await presentedItemURL == profileAssistant.profileURL {
          await profileAssistant.reloadProfile()
        }
        await profileAssistant.reloadAllProfiles()
      }
    }

    #if !canImport(FoundationEssentials)
      func presentedItemDidChangeUbiquityAttributes(_ attributes: Set<URLResourceKey>) {
        guard presentedItemURL == profileURL, attributes.contains(.contentModificationDateKey)
        else {
          return
        }
        let contentModificationDate = try? profileURL.resourceValues(
          forKeys: [.contentModificationDateKey]
        ).contentModificationDate
        profileLastContentModificationDate = contentModificationDate ?? .now
      }

      var observedPresentedItemUbiquityAttributes: Set<URLResourceKey> {
        [.contentModificationDateKey]
      }
    #endif

    func accommodatePresentedSubitemDeletion(at url: URL) async throws {
      guard await isValidURLScope else {
        return
      }

      guard url.isProfile, url.deletingLastPathComponent() == presentedItemURL else {
        return
      }

      // If profile removed, reload all profiles is needed.
      // If removed profile url is the active profile url, we should also fallback active profile
      // to default profile.
      guard profileURL == url else {
        await profileAssistant.reloadAllProfiles()
        return
      }

      profileURL = await profileAssistant.virtualProfileURL
      await profileAssistant.reloadAllProfiles()
    }

    func presentedSubitemDidAppear(at url: URL) {
      Task {
        guard await isValidURLScope else {
          return
        }

        guard url.isProfile, url.deletingLastPathComponent() == presentedItemURL else {
          return
        }
        await profileAssistant.reloadAllProfiles()
      }
    }

    func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) {
      Task {
        guard await isValidURLScope else {
          return
        }

        guard oldURL.isProfile, oldURL.deletingLastPathComponent() == presentedItemURL else {
          return
        }

        // If oldURL is not the current active profile url, reload all profiles in folder, else
        // update active profile.
        guard profileURL == oldURL else {
          await profileAssistant.reloadAllProfiles()
          return
        }

        // If newURL's parent directory is same as the current active profiles directory means we
        // have renamed profile, so we need update profileURL. else we should fallback to use
        // virtual default profile url as active profile url.
        guard newURL.deletingLastPathComponent() != presentedItemURL else {
          profileURL = newURL
          await profileAssistant.reloadAllProfiles()
          return
        }

        // Profile has been moved to outside of the current profiles directory. we should fallback
        // to the virtual default profile.
        profileURL = await profileAssistant.virtualProfileURL

        // Also, update profile resources.
        await profileAssistant.reloadAllProfiles()
      }
    }

    func presentedSubitemDidChange(at url: URL) {
      Task {
        guard await isValidURLScope else {
          return
        }

        guard url.isProfile, url.deletingLastPathComponent() == presentedItemURL else {
          return
        }

        if url == profileURL {
          await profileAssistant.reloadProfile()
        }
        await profileAssistant.reloadAllProfiles()
      }
    }
  }
}

extension URL {
  fileprivate var isProfile: Bool {
    isFileURL && pathExtension == .profilePathExtension
  }
}
