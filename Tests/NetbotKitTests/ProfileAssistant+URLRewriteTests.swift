// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import Testing
import _ProfileSupport

@testable import NetbotKit

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import struct Foundation.IndexSet
#else
  import Foundation
#endif

@Suite(.tags(.urlRewrite))
struct URLRewriteManagementTests {

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertURLRewrite() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var urlRewrite = URLRewrite()
      urlRewrite.type = .found
      urlRewrite.pattern = "(?:http://)?swift.org"
      urlRewrite.destination = "https://swift.org"

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(urlRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """

        [URL Rewrite]
        found, (?:http://)?swift.org, https://swift.org
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertURLRewriteIntoProfileWhereURLRewritesSectionExists() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [URL Rewrite]
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var urlRewrite = URLRewrite()
      urlRewrite.type = .found
      urlRewrite.pattern = "(?:http://)?swift.org"
      urlRewrite.destination = "https://swift.org"

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(urlRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [URL Rewrite]
        found, (?:http://)?swift.org, https://swift.org
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertURLRewriteIntoProfileWhereURLRewritesSectionExistsAndItemsNotEmpty() async throws
  {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [URL Rewrite]
      found, (?:http://)?apple.com, https://apple.com
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var urlRewrite = URLRewrite()
      urlRewrite.type = .found
      urlRewrite.pattern = "(?:http://)?swift.org"
      urlRewrite.destination = "https://swift.org"

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(urlRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [URL Rewrite]
        found, (?:http://)?apple.com, https://apple.com
        found, (?:http://)?swift.org, https://swift.org
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertURLRewriteIntoProfileWhereURLRewritesSectionAtMiddleOfProfile() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Policies]
      DIRECT,direct

      [URL Rewrite]
      found, (?:http://)?apple.com, https://apple.com

      [Rule]
      DOMAIN-SUFFIX, swift.org, DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var urlRewrite = URLRewrite()
      urlRewrite.type = .found
      urlRewrite.pattern = "(?:http://)?swift.org"
      urlRewrite.destination = "https://swift.org"

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(urlRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Policies]
        DIRECT,direct

        [URL Rewrite]
        found, (?:http://)?apple.com, https://apple.com
        found, (?:http://)?swift.org, https://swift.org

        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func replaceURLRewrite() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var urlRewrite = URLRewrite()
      urlRewrite.pattern = "(?:http://)?apple.com"
      urlRewrite.destination = "https://apple.com"
      try """
      [URL Rewrite]
      found, (?:http://)?apple.com, https://apple.com
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var newURLRewrite = URLRewrite()
      newURLRewrite.pattern = "(?:http://)?swift.org"
      newURLRewrite.destination = "https://swift.org"

      await #expect(throws: Never.self) {
        try await profileAssistant.replace(urlRewrite, with: newURLRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [URL Rewrite]
        found, (?:http://)?swift.org, https://swift.org
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func moveURLRewrites() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [URL Rewrite]
      found, (?:http://)?apple.com, https://apple.com
      found, (?:http://)?swift.org, https://swift.org
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.moveURLRewrites(fromOffsets: IndexSet([1]), toOffset: 0)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [URL Rewrite]
        found, (?:http://)?swift.org, https://swift.org
        found, (?:http://)?apple.com, https://apple.com
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func removeURLRewrites() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var urlRewrite = URLRewrite()
      urlRewrite.pattern = "(?:http://)?apple.com"
      urlRewrite.destination = "https://apple.com"
      try """
      [URL Rewrite]
      found, (?:http://)?apple.com, https://apple.com
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.removeURLRewrites(atOffsets: IndexSet([0]))
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [URL Rewrite]
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func removeSpecifiedURLRewrite() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var urlRewrite = URLRewrite()
      urlRewrite.pattern = "(?:http://)?apple.com"
      urlRewrite.destination = "https://apple.com"
      try """
      [URL Rewrite]
      found, (?:http://)?apple.com, https://apple.com
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.delete(urlRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [URL Rewrite]
        """
      #expect(finalize == expected)
    }
  }
}
