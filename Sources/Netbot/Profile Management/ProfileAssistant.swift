//
// See LICENSE.txt for license information
//

public import Logging
public import _ResourceProcessing

#if canImport(FoundationEssentials)
  public import FoundationEssentials
  private import FoundationInternationalization
#else
  public import Foundation
  private import UniformTypeIdentifiers
#endif

#if canImport(SwiftData)
  public import SwiftData
#endif

@available(swift 5.9)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#if canImport(SwiftData)
  @ModelActor
#endif
@globalActor public actor ProfileAssistant {

  #if canImport(SwiftData)
    public static let shared = ProfileAssistant(modelContainer: modelContainer)

    /// Default model container for `Profile`.
    private static var modelContainer: ModelContainer {
      let schema: Schema = Schema(versionedSchema: _VersionedSchema.self)
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
      let modelContainer = try! ModelContainer(for: schema, configurations: [configuration])
      return modelContainer
    }
  #else
    public static let shared = ProfileAssistant()

    public init() {}
  #endif

  /// Current active profile URL.
  public private(set) var profileURL = URL.profile

  /// Current active profiles directory.
  public private(set) var profilesDirectory = URL.profile.deletingLastPathComponent()

  /// A virtual profile URL. Load profile from virtual profile url always return a default `Profile` instance and never failed.
  public var virtualProfileURL: URL {
    profilesDirectory.appending(path: "Default").appendingPathExtension(.profilePathExtension)
  }

  nonisolated public let logger = Logger(label: "Profile")

  nonisolated public let profileResource = ProfileResource()

  var filePresenter: _FilePresenter? {
    didSet {
      if let oldValue {
        NSFileCoordinator.removeFilePresenter(oldValue)
      }
      if let filePresenter {
        NSFileCoordinator.addFilePresenter(filePresenter)
      }
    }
  }

  /// Last error for loading profile.
  public private(set) var lastLoadError: (any Error)?

  private var profileLoadingTask: Task<Void, Never>?

  private var profileAutoreload = false

  /// Set current active profile URL to new url.
  public func setProfileURL(_ newURL: URL) {
    profileURL = newURL
  }

  /// Set current active profiles directory to new directory.
  ///
  /// When profiles directory changed, the current active profile URL will also be changed to adopt new profiles directory. whitch
  /// means if there is a configuration file has the same name as original profile then the file URL will be use as active profile URL,
  /// else the  virtual default configuration file URL will be use.
  public func setProfilesDirectory(_ newDirectory: URL) {
    profilesDirectory = newDirectory

    if profileAutoreload {
      filePresenter = _FilePresenter(presentedItemURL: newDirectory)
    }

    let profileURL =
      profilesDirectory
      .appending(path: profileURL.suggestedFilename)
      .appendingPathExtension(.profilePathExtension)
    setProfileURL(profileURL)
  }

  public func setAutoreloadEnabled(_ isEnabled: Bool) {
    profileAutoreload = isEnabled

    guard isEnabled else {
      // Remove profiles directory file presenter, so we will not receive any notification when
      // profile modified from other process.
      filePresenter = nil
      return
    }

    // If profiles directory file presenter already exists, we can ignored.
    guard filePresenter == nil else {
      return
    }

    filePresenter = _FilePresenter(presentedItemURL: profilesDirectory)
  }

  /// Reload in-used profile into database.
  ///
  /// If current active profile URL load failed an error will stored in `lastLoadError`, and a virtual default profile will be loaded.
  public func reloadProfile() async {
    // Cancel current loading task.
    if let profileLoadingTask, !profileLoadingTask.isCancelled {
      profileLoadingTask.cancel()
    }
    self.profileLoadingTask = nil

    await waitUntilProfileLoaded()
  }

  /// Reload all profiles in the current active profiles directory, profiles contains invalid syntax will be ignored.
  nonisolated public func reloadAllProfiles() async {
    var profiles: [ProfileInfo] = await loadAllProfiles(at: profilesDirectory).map {
      .init(
        url: $0.url, numberOfRules: $0.lazyForwardingRules.count,
        numberOfProxies: $0.lazyProxies.count)
    }
    profiles.sort(using: KeyPathComparator(\.name))
    await Task { @MainActor in
      profileResource.profiles = profiles
    }.value
  }

  /// Remove all loaded data from container.
  public func erase() async throws {
    #if canImport(SwiftData)
      // Remove expired data.
      var fd = FetchDescriptor<Profile.PersistentModel>()
      fd.relationshipKeyPathsForPrefetching = [
        \.lazyProxies,
        \.lazyProxyGroups,
        \.lazyForwardingRules,
        \.lazyDNSMappings,
        \.lazyURLRewrites,
        \.lazyHTTPFieldsRewrites,
        \.lazyStubbedHTTPResponses,
      ]
      let profiles = try modelContext.fetch(fd)
      for profile in profiles {
        for model in profile.lazyForwardingRules {
          modelContext.delete(model)
        }
        for model in profile.lazyProxyGroups {
          modelContext.delete(model)
        }
        for model in profile.lazyProxies {
          modelContext.delete(model)
        }
        for model in profile.lazyDNSMappings {
          modelContext.delete(model)
        }
        for model in profile.lazyURLRewrites {
          modelContext.delete(model)
        }
        for model in profile.lazyHTTPFieldsRewrites {
          modelContext.delete(model)
        }
        for model in profile.lazyStubbedHTTPResponses {
          modelContext.delete(model)
        }
        modelContext.delete(profile)
      }

      try modelContext.save()
    #endif
  }

  /// Load profile identified by file url.
  ///
  /// Never failed to load virtual profile.
  ///
  /// - Parameter url: URL for the profile file.
  /// - Returns: Loaded profile if success.
  nonisolated public func profile(identified url: URL) async throws -> Profile {
    guard await url != virtualProfileURL else {
      return Profile()
    }
    return try await withCheckedThrowingContinuation { continuation in
      let readIntent = NSFileAccessIntent.readingIntent(with: url)
      let coordinator = NSFileCoordinator(filePresenter: nil)
      coordinator.coordinate(with: [readIntent], queue: .init()) { error in
        do {
          if let error {
            throw error
          }

          let filePath = readIntent.url.path(percentEncoded: false)
          guard FileManager.default.fileExists(atPath: filePath) else {
            throw ProfileLoadError.notFound
          }
          let parseInput = try String(contentsOf: readIntent.url, encoding: .utf8)
          var profile = try Profile(parseInput, strategy: .profile)
          profile.url = url
          profile.contentModificationDate = readIntent.url.contentModificationDate ?? .now
          continuation.resume(returning: profile)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  /// Load profile identified by name.
  ///
  /// The profile named `name` will be loaded from the same directory as the currentt in-used profile.
  ///
  /// - Parameter name: Name of the profile to be loaded.
  /// - Returns: Loaded profile if success.
  nonisolated public func profile(identified name: String) async throws -> Profile {
    let profilesDirectory = await profileURL.deletingLastPathComponent()
    let url = profilesDirectory.appending(path: name).appendingPathExtension(.profilePathExtension)
    return try await profile(identified: url)
  }

  private func waitUntilProfileLoaded() async {
    if let task = profileLoadingTask {
      await task.value
    } else {
      let newTask = Task {
        let profileURL = profileURL
        let profileName = profileURL.deletingPathExtension().lastPathComponent
        do {
          logger.trace("Loading profile \(profileName)...")
          let profile = try await profile(identified: profileURL)

          try Task.checkCancellation()

          // Ignore SwiftData errors.
          try? await loadProfile(profile)
          lastLoadError = nil
          profileLoadingTask = nil
          logger.trace("Completed loading profile \(profileName)")
        } catch _ as CancellationError {
          logger.trace("Cancelled loading profile \(profileName)")
        } catch {
          lastLoadError = error
          profileLoadingTask = nil
          logger.error("Failed to load profile \(profileName) error: \(error)")
        }
      }
      profileLoadingTask = newTask
      await newTask.value
    }
  }

  /// Load specific profile into database.
  /// - Parameter profile: Profile to load.
  func loadProfile(_ profile: Profile) async throws {
    #if canImport(SwiftData)
      try await erase()

      let persistentModel = Profile.PersistentModel()

      // Load all data into model container.
      try modelContext.transaction {
        persistentModel.mergeValues(profile)
        modelContext.insert(persistentModel)

        // Load built-in proxies at the beginning.
        let lazyProxies = profile.lazyProxies.sorted(using: KeyPathComparator(\.creationDate))
        let earliestDate = lazyProxies.first?.creationDate ?? .now
        var proxy = AnyProxy.PersistentModel()
        proxy.name = "DIRECT"
        proxy.kind = .direct
        proxy.source = AnyProxy.Source.builtin.rawValue
        proxy.creationDate = earliestDate.advanced(by: -3)
        persistentModel.lazyProxies.append(proxy)

        proxy = AnyProxy.PersistentModel()
        proxy.name = "REJECT"
        proxy.kind = .reject
        proxy.source = AnyProxy.Source.builtin.rawValue
        proxy.creationDate = earliestDate.advanced(by: -2)
        persistentModel.lazyProxies.append(proxy)

        proxy = AnyProxy.PersistentModel()
        proxy.name = "REJECT-TINYGIF"
        proxy.kind = .rejectTinyGIF
        proxy.source = AnyProxy.Source.builtin.rawValue
        proxy.creationDate = earliestDate.advanced(by: -1)
        persistentModel.lazyProxies.append(proxy)

        for data in lazyProxies {
          let model = AnyProxy.PersistentModel()
          model.mergeValues(data)
          persistentModel.lazyProxies.append(model)
        }

        for data in profile.lazyProxyGroups {
          let model = AnyProxyGroup.PersistentModel()
          model.mergeValues(data)
          model.lazyProxies = persistentModel.lazyProxies.filter {
            data.lazyProxies.contains($0.name)
          }
          persistentModel.lazyProxyGroups.append(model)
        }

        for (order, data) in profile.lazyForwardingRules.enumerated() {
          let model = AnyForwardingRule.PersistentModel()
          model.mergeValues(data)
          model.order = order
          model.lazyProxy = persistentModel.lazyProxies.first { $0.name == data.foreignKey }
          model.lazyProxyGroup = persistentModel.lazyProxyGroups.first {
            $0.name == data.foreignKey
          }
          persistentModel.lazyForwardingRules.append(model)
        }

        for data in profile.lazyDNSMappings {
          let model = DNSMapping.PersistentModel()
          model.mergeValues(data)
          persistentModel.lazyDNSMappings.append(model)
        }

        for data in profile.lazyHTTPFieldsRewrites {
          let model = HTTPFieldsRewrite.PersistentModel()
          model.mergeValues(data)
          persistentModel.lazyHTTPFieldsRewrites.append(model)
        }

        for data in profile.lazyURLRewrites {
          let model = URLRewrite.PersistentModel()
          model.mergeValues(data)
          persistentModel.lazyURLRewrites.append(model)
        }

        for data in profile.lazyStubbedHTTPResponses {
          let model = StubbedHTTPResponse.PersistentModel()
          model.mergeValues(data)
          persistentModel.lazyStubbedHTTPResponses.append(model)
        }
      }

      try modelContext.save()
    #endif
  }

  nonisolated private func loadAllProfiles(at url: URL) async -> [Profile] {
    await withTaskGroup(of: Optional<Profile>.self) { g in
      let urls: [URL] = await withCheckedContinuation { continuation in
        let readIntent = NSFileAccessIntent.readingIntent(with: url)
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(with: [readIntent], queue: .init()) { error in
          do {
            guard error == nil else {
              continuation.resume(returning: [])
              return
            }

            #if canImport(Darwin)
              let fileURLs = try FileManager.default
                .contentsOfDirectory(
                  at: readIntent.url,
                  includingPropertiesForKeys: nil,
                  options: [.skipsHiddenFiles]
                )
                .filter {
                  try $0.pathExtension == .profilePathExtension
                }
            #else
              let fileURLs: [URL] = try FileManager.default
                .contentsOfDirectory(atPath: readIntent.url.path(percentEncoded: false))
                .compactMap {
                  guard $0.hasSuffix(.profilePathExtension) else {
                    return nil
                  }
                  return URL(filePath: $0)
                }
            #endif
            continuation.resume(returning: fileURLs)
          } catch {
            continuation.resume(returning: [])
          }
        }
      }

      for url in urls {
        g.addTask {
          await withCheckedContinuation { continuation in
            let readIntent = NSFileAccessIntent.readingIntent(with: url)
            let coordinator = NSFileCoordinator(filePresenter: nil)
            coordinator.coordinate(with: [readIntent], queue: .init()) { error in
              guard error == nil else {
                continuation.resume(returning: nil)
                return
              }

              Task {
                do {
                  self.logger.trace("Loading profile \(url.suggestedFilename)...")
                  let profile = try await self.profile(identified: url)
                  self.logger.trace("Completed loading profile \(url.suggestedFilename)")
                  continuation.resume(returning: profile)
                } catch {
                  self.logger.error(
                    "Failed to load profile \(url.suggestedFilename) error: \(error)")
                  continuation.resume(returning: nil)
                }
              }
            }
          }
        }
      }

      var profiles: [Profile] = []
      for await profile in g {
        if let profile {
          // Ignore profile named `Default`.
          if profile.name != "Default" {
            profiles.append(profile)
          }
        }
      }
      profiles.insert(Profile(), at: 0)

      return profiles
    }
  }

  /// Modify in-used Profile contents within file access intents.
  func modify(
    accessor: @escaping @Sendable (NSFileAccessIntent, NSFileAccessIntent) throws -> Void
  ) async throws {
    try await withCheckedThrowingContinuation { continuation in
      let readIntent = NSFileAccessIntent.readingIntent(with: profileURL)
      let writeIntent = NSFileAccessIntent.writingIntent(with: profileURL, options: .forReplacing)
      let coordinator = NSFileCoordinator(filePresenter: filePresenter)
      coordinator.coordinate(with: [readIntent, writeIntent], queue: .init()) { error in
        do {
          if let error {
            throw error
          }

          try accessor(readIntent, writeIntent)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
