//
// See LICENSE.txt for license information
//

import Testing

@testable import NetbotData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif
#if canImport(SwiftData)
  import SwiftData
#endif

@Suite(.tags(.profileAssistant, .swiftData))
struct ProfileAssistantTests {

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func initialData() throws {
    #if canImport(SwiftData)
      let schema: Schema = Schema(versionedSchema: _VersionedSchema.self)
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
      let modelContainer = try! ModelContainer(for: schema, configurations: configuration)
      let profileAssistant = ProfileAssistant(modelContainer: modelContainer)
      let modelContext = ModelContext(profileAssistant.modelContainer)
      var numberOfItems = try modelContext.fetchCount(FetchDescriptor<Profile.PersistentModel>())
      #expect(numberOfItems == 0)

      numberOfItems = try modelContext.fetchCount(
        FetchDescriptor<AnyForwardingRule.PersistentModel>())
      #expect(numberOfItems == 0)

      numberOfItems = try modelContext.fetchCount(FetchDescriptor<AnyProxy.PersistentModel>())
      #expect(numberOfItems == 0)

      numberOfItems = try modelContext.fetchCount(FetchDescriptor<AnyProxyGroup.PersistentModel>())
      #expect(numberOfItems == 0)
    #endif
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func setFilePresentor() async throws {}

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func setProfileURL() async throws {
    try await withManagedProfile { profileAssistant in
      var profileURL = await profileAssistant.profileURL
      #expect(profileURL != .profile)
      await profileAssistant.setProfileURL(.profile)
      profileURL = await profileAssistant.profileURL
      #expect(profileURL == .profile)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func setProfilesDirectory() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL
      let profilesDirectory = await profileAssistant.profilesDirectory
      #expect(profilesDirectory != .profile.deletingLastPathComponent())
      await profileAssistant.setProfilesDirectory(.profile.deletingLastPathComponent())
      let newProfileURL = await profileAssistant.profileURL
      let expectedProfileURL = URL.profile.deletingLastPathComponent().appending(
        component: profileURL.lastPathComponent)
      #expect(newProfileURL == expectedProfileURL)
      #expect(await profileAssistant.filePresenter == nil)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func setProfilesDirectoryIfAutoreloadIsEnabled() async throws {
    try await withManagedProfile { profileAssistant in
      await profileAssistant.setAutoreloadEnabled(true)
      await profileAssistant.setProfilesDirectory(.profile.deletingLastPathComponent())
      let filePresenter = await profileAssistant.filePresenter
      #expect(filePresenter != nil)
      #expect(filePresenter?.presentedItemURL == .profile.deletingLastPathComponent())
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func enableAutoreload() async throws {
    try await withManagedProfile { profileAssistant in
      #expect(await profileAssistant.filePresenter == nil)
      await profileAssistant.setAutoreloadEnabled(true)
      #expect(await profileAssistant.filePresenter != nil)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func disableAutoreload() async throws {
    try await withManagedProfile { profileAssistant in
      #expect(await profileAssistant.filePresenter == nil)
      await profileAssistant.setAutoreloadEnabled(true)
      #expect(await profileAssistant.filePresenter != nil)
      await profileAssistant.setAutoreloadEnabled(false)
      #expect(await profileAssistant.filePresenter == nil)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func ignoreEnableAutoreloadIfItAlreadyEnabled() async throws {
    try await withManagedProfile { profileAssistant in
      #expect(await profileAssistant.filePresenter == nil)
      await profileAssistant.setAutoreloadEnabled(true)
      let filePresenter = await profileAssistant.filePresenter
      #expect(filePresenter != nil)
      await profileAssistant.setAutoreloadEnabled(true)
      #expect(await profileAssistant.filePresenter === filePresenter)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func reloadProfile() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      let file = """
        [General]
        log-level = error
        dns-servers = 8.8.8.8
        exceptions = 127.0.1.1
        http-listen-address = 127.0.0.1
        http-listen-port = 6152
        socks-listen-address = 127.0.0.1
        socks-listen-port = 6153
        exclude-simple-hostnames = true

        [MitM]
        skip-certification-verification = true
        base62-encoded-p12-string = MLDFI3903rNDSLF
        hostnames = swift.org, twitter.com
        passphrase = LDJFIEH7

        [Proxy]
        HTTP = http, server-address = example.com, port = 1234

        [Proxy Group]
        TV = select, proxies = DIRECT

        [Rule]
        DOMAIN-SUFFIX,example.com,DIRECT

        """
      try file.write(to: profileURL, atomically: true, encoding: .utf8)

      await profileAssistant.reloadProfile()
      let lastLoadError = await profileAssistant.lastLoadError
      #expect(lastLoadError == nil)

      #if canImport(SwiftData)
        let modelContext = ModelContext(profileAssistant.modelContainer)

        let profiles = try modelContext.fetchCount(FetchDescriptor<Profile.PersistentModel>())
        #expect(profiles == 1)

        let rules = try modelContext.fetchCount(
          FetchDescriptor<AnyForwardingRule.PersistentModel>())
        #expect(rules == 1)

        let proxies = try modelContext.fetchCount(FetchDescriptor<AnyProxy.PersistentModel>())
        #expect(proxies == 4)

        let policyGroups = try modelContext.fetchCount(
          FetchDescriptor<AnyProxyGroup.PersistentModel>())
        #expect(policyGroups == 1)
      #endif
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func loadProfileFromURLThatCannotBeOpened() async throws {
    try await withManagedProfile { profileAssistant in
      let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      await profileAssistant.setProfileURL(url)
      await profileAssistant.reloadProfile()
      let lastLoadError = await profileAssistant.lastLoadError
      #expect(lastLoadError != nil)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func loadProfileContainsInvalidPolicy() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL
      let file = """
        [Proxy]
        UNKNOWN = unknown

        """
      try file.write(to: profileURL, atomically: true, encoding: .utf8)

      await profileAssistant.reloadProfile()
      let lastLoadError = await profileAssistant.lastLoadError
      #expect(lastLoadError != nil)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func loadProfileContainsInvalidPolicyGroup() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL
      let file = """
        [Proxy Group]
        UNKNOWN = unknown, policies = DIRECT

        """
      try file.write(to: profileURL, atomically: true, encoding: .utf8)

      await profileAssistant.reloadProfile()
      let lastLoadError = await profileAssistant.lastLoadError
      #expect(lastLoadError != nil)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func loadProfileContainsInvalidRule() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL
      let file = """
        [Rule]
        UNKNOWN,example.com,DIRECT

        """
      try file.write(to: profileURL, atomically: true, encoding: .utf8)

      await profileAssistant.reloadProfile()
      let lastLoadError = await profileAssistant.lastLoadError
      #expect(lastLoadError != nil)
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func profileIdentifiedByURL() async throws {
    try await withManagedProfile { profileAssistant in
      await #expect(throws: Never.self) {
        try await profileAssistant.profile(
          identified: profileAssistant.profileURL.suggestedFilename
        )
      }
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func profileIdentifiedByURLThatProfileWithURLIsNotExist() async throws {
    try await withManagedProfile { profileAssistant in
      await #expect(throws: ProfileLoadError.self) {
        try await profileAssistant.profile(
          identified: profileAssistant.profileURL.deletingLastPathComponent()
            .appendingPathComponent("ABC", conformingTo: .profile)
        )
      }
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func profileIdentifiedByName() async throws {
    try await withManagedProfile { profileAssistant in
      await #expect(throws: Never.self) {
        try await profileAssistant.profile(
          identified: profileAssistant.profileURL.suggestedFilename
        )
      }
    }
  }

  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func profileIdentifiedByNameThatProfileWithNameIsNotExist() async throws {
    try await withManagedProfile { profileAssistant in
      await #expect(throws: ProfileLoadError.self) {
        try await profileAssistant.profile(identified: "suggestedFilename")
      }
    }
  }
}
