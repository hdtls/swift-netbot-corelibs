//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Testing
import _ProfileSupport

@testable import Netbot

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

  @available(SwiftStdlib 5.9, *)
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

  @available(SwiftStdlib 5.9, *)
  @Test func setProfileURL() async throws {
    try await withManagedProfile { profileAssistant in
      var profileURL = await profileAssistant.profileURL
      #expect(profileURL != .profile)
      await profileAssistant.setProfileURL(.profile)
      profileURL = await profileAssistant.profileURL
      #expect(profileURL == .profile)
    }
  }

  @available(SwiftStdlib 5.9, *)
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
    }
  }

  @available(SwiftStdlib 5.9, *)
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

  @available(SwiftStdlib 5.9, *)
  @Test func loadProfileFromURLThatCannotBeOpened() async throws {
    try await withManagedProfile { profileAssistant in
      let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      await profileAssistant.setProfileURL(url)
      await profileAssistant.reloadProfile()
      let lastLoadError = await profileAssistant.lastLoadError
      #expect(lastLoadError != nil)
    }
  }

  @available(SwiftStdlib 5.9, *)
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

  @available(SwiftStdlib 5.9, *)
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

  @available(SwiftStdlib 5.9, *)
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

  @available(SwiftStdlib 5.9, *)
  @Test func profileIdentifiedByURL() async throws {
    try await withManagedProfile { profileAssistant in
      await #expect(throws: Never.self) {
        try await profileAssistant.profile(
          identified: profileAssistant.profileURL.suggestedFilename
        )
      }
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func profileIdentifiedByURLThatProfileWithURLIsNotExist() async throws {
    try await withManagedProfile { profileAssistant in
      await #expect(throws: ProfileLoadError.self) {
        try await profileAssistant.profile(
          identified: profileAssistant.profileURL.deletingLastPathComponent()
            .appending(path: "ABC").appendingPathExtension(.profilePathExtension)
        )
      }
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func profileIdentifiedByName() async throws {
    try await withManagedProfile { profileAssistant in
      await #expect(throws: Never.self) {
        try await profileAssistant.profile(
          identified: profileAssistant.profileURL.suggestedFilename
        )
      }
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func profileIdentifiedByNameThatProfileWithNameIsNotExist() async throws {
    try await withManagedProfile { profileAssistant in
      await #expect(throws: ProfileLoadError.self) {
        try await profileAssistant.profile(identified: "suggestedFilename")
      }
    }
  }
}
