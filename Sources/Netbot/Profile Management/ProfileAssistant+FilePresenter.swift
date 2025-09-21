//
// See LICENSE.txt for license information
//

import AnlzrReports
import NIOConcurrencyHelpers
import Preference
import _PreferenceSupport
import _ProfileSupport

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import class Foundation.OperationQueue
#else
  import Foundation
#endif

@available(SwiftStdlib 5.9, *)
extension ProfileAssistant {

  #if canImport(FoundationEssentials)
    typealias NSObject = AnyObject
  #endif

  /// FilePresenter used to observe changes in current active profiles directory.
  final class _FilePresenter: NSObject, NSFilePresenter, @unchecked Sendable {

    /// An object store identity of operation.
    final class Permitted: Sendable {
      @LockableTracked fileprivate var isPermitted: Bool
      fileprivate init() {
        self._isPermitted = .init(false)
      }

      func enter() {
        isPermitted = true
      }

      func leave() {
        isPermitted = false
      }
    }

    let presentedItemURL: URL?

    let presentedItemOperationQueue = OperationQueue()

    private weak var profileAssistant: ProfileAssistant?

    @Preference(Prefs.Name.profileURL, store: .__shared)
    private var profileURL: URL = .profile

    @Preference(Prefs.Name.profileLastContentModificationDate, store: .__shared)
    private var profileLastContentModificationDate = Date.now

    @Preference(Prefs.Name.profilesDirectory, store: .__shared)
    private var profilesDirectory: URL = .profile.deletingLastPathComponent()

    @Preference(Prefs.Name.profileAutoreload, store: .__shared)
    private var profileAutoreload = false

    let permitted = Permitted()

    /// Create FilePresenter with current active profiles directory.
    init(presentedItemURL: URL, profileAssistant: ProfileAssistant) {
      self.presentedItemURL = presentedItemURL
      self.profileAssistant = profileAssistant
      #if !canImport(FoundationEssentials)
        super.init()
        NSFileCoordinator.addFilePresenter(self)
      #endif
    }

    #if !canImport(FoundationEssentials)
      deinit {
        NSFileCoordinator.removeFilePresenter(self)
      }
    #endif

    func accommodatePresentedItemDeletion() async throws {
      // There we don't call reload because both `profileURL` and
      // `profilesDirectory` changes perform reload automatically.

      if presentedItemURL?.isProfile ?? false {
        // If current active profile is removed, fallback to virtual
        // default profile, else ignored.
        profileURL = await profileAssistant?.virtualProfileURL ?? .profile
      } else {
        // If entire profiles directory is removed, fallback to default
        // profiles directory.
        profilesDirectory = URL.profile.deletingLastPathComponent()
      }
    }

    func presentedItemDidMove(to newURL: URL) {
      Task {
        let parent = presentedItemURL?.deletingLastPathComponent()

        if presentedItemURL?.isProfile ?? false {
          if newURL.deletingLastPathComponent() == parent {
            // Because current active profile name is changed, so we need
            // update profile url. also here we can't prevent reload happen.
            profileURL = newURL
          } else {
            // Current active profile has been move to outside of the
            // profiles directory, so we need to reset active profile to
            // virtual default.
            profileURL = await profileAssistant?.virtualProfileURL ?? .profile
          }

          await profileAssistant?.reloadAllProfiles()
        } else {

          // If newURL and current active profiles directory has same parent, that means we have
          // renamed profiles folder, so we should update active profiles directory to the newURL.
          // else we should fallback to ues default profiles directory.
          guard newURL.deletingLastPathComponent() == parent else {
            profilesDirectory = .profile.deletingLastPathComponent()
            return
          }

          // In this situation we move entire directory, the contents does
          // not changed, we actually don't need reload profiles, but for
          // current observation we can't prevent reload triggered by
          // `profilesDirectory` changes.
          profilesDirectory = newURL
        }
      }
    }

    func presentedItemDidChange() {
      Task {
        // We don't reload profile if content is modified by our's
        // application.
        if presentedItemURL?.isProfile ?? false && !permitted.isPermitted && profileAutoreload {
          await profileAssistant?.reloadProfile()
          permitted.leave()
        }
      }
    }

    func accommodatePresentedSubitemDeletion(at url: URL) async throws {
      guard url.isProfile, url.deletingLastPathComponent() == presentedItemURL else {
        return
      }

      // If profile removed, reload all profiles is needed.
      // If removed profile url is the active profile url, we should
      // also fallback active profile to default profile.
      if profileURL == url {
        profileURL = await profileAssistant?.virtualProfileURL ?? .profile
      }

      await profileAssistant?.reloadAllProfiles()
    }

    func presentedSubitemDidAppear(at url: URL) {
      Task {
        guard url.isProfile, url.deletingLastPathComponent() == presentedItemURL else {
          return
        }
        await profileAssistant?.reloadAllProfiles()
      }
    }

    func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) {
      Task {
        guard oldURL.isProfile, oldURL.deletingLastPathComponent() == presentedItemURL else {
          return
        }

        // If oldURL is not the current active profile url, reload all profiles in folder, else
        // update active profile.
        guard profileURL == oldURL else {
          await profileAssistant?.reloadAllProfiles()
          return
        }

        // If newURL's parent directory is same as the current active profiles directory means we
        // have renamed profile, so we need update profileURL. else we should fallback to use
        // virtual default profile url as active profile url.
        if newURL.deletingLastPathComponent() != presentedItemURL {
          // Profile has been moved to outside of the current profiles directory. we should fallback
          // to the virtual default profile.
          profileURL = await profileAssistant?.virtualProfileURL ?? .profile
        } else {
          profileURL = newURL
        }

        // Also, update profile resources.
        await profileAssistant?.reloadAllProfiles()
      }
    }

    func presentedSubitemDidChange(at url: URL) {
      Task {
        defer { permitted.leave() }
        guard url.isProfile, url.deletingLastPathComponent() == presentedItemURL else { return }
        guard url == profileURL else { return }

        // Once profile content changed, modify `profileLastContentModificationDate`
        // to notify extension to reload profile.
        profileLastContentModificationDate = url.contentModificationDate ?? .now

        // To prevent duplicated database modification, reload only when
        // `profileAutoreload` is enabled.
        guard !permitted.isPermitted && profileAutoreload else { return }

        await profileAssistant?.reloadProfile()
      }
    }
  }
}

@available(SwiftStdlib 5.3, *)
extension URL {
  var isProfile: Bool {
    isFileURL && pathExtension == .profilePathExtension
  }
}
