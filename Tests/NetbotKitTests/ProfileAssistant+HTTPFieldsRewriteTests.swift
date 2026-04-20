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

@Suite(.tags(.httpFieldsRewrite))
struct HTTPFieldsRewriteManagementTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertHTTPFieldsRewrite() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var httpFieldsRewrite = HTTPFieldsRewrite()
      httpFieldsRewrite.direction = .request
      httpFieldsRewrite.pattern = "^http://example.com"
      httpFieldsRewrite.action = .add
      httpFieldsRewrite.name = "DNT"
      httpFieldsRewrite.value = "1"
      httpFieldsRewrite.replacement = ""

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(httpFieldsRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """

        [HTTP Fields Rewrite]
        request ^http://example.com add DNT 1
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertHTTPFieldsRewriteIntoProfileWhereHTTPFieldsRewritesSectionExists() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [HTTP Fields Rewrite]
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var httpFieldsRewrite = HTTPFieldsRewrite()
      httpFieldsRewrite.direction = .request
      httpFieldsRewrite.pattern = "^http://example.com"
      httpFieldsRewrite.action = .add
      httpFieldsRewrite.name = "DNT"
      httpFieldsRewrite.value = "1"
      httpFieldsRewrite.replacement = ""

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(httpFieldsRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [HTTP Fields Rewrite]
        request ^http://example.com add DNT 1
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test
  func insertHTTPFieldsRewriteIntoProfileWhereHTTPFieldsRewritesSectionExistsAndItemsNotEmpty()
    async throws
  {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [HTTP Fields Rewrite]
      request ^http://example.com remove Cookie
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var httpFieldsRewrite = HTTPFieldsRewrite()
      httpFieldsRewrite.direction = .request
      httpFieldsRewrite.pattern = "^http://example.com"
      httpFieldsRewrite.action = .add
      httpFieldsRewrite.name = "DNT"
      httpFieldsRewrite.value = "1"
      httpFieldsRewrite.replacement = ""

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(httpFieldsRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [HTTP Fields Rewrite]
        request ^http://example.com remove Cookie
        request ^http://example.com add DNT 1
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertHTTPFieldsRewriteIntoProfileWhereHTTPFieldsRewritesSectionAtMiddleOfProfile()
    async throws
  {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Policies]
      DIRECT,direct

      [HTTP Fields Rewrite]
      request ^http://example.com remove Cookie

      [Rule]
      DOMAIN-SUFFIX, swift.org, DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var httpFieldsRewrite = HTTPFieldsRewrite()
      httpFieldsRewrite.direction = .request
      httpFieldsRewrite.pattern = "^http://example.com"
      httpFieldsRewrite.action = .add
      httpFieldsRewrite.name = "DNT"
      httpFieldsRewrite.value = "1"
      httpFieldsRewrite.replacement = ""

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(httpFieldsRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Policies]
        DIRECT,direct

        [HTTP Fields Rewrite]
        request ^http://example.com remove Cookie
        request ^http://example.com add DNT 1

        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func replaceHTTPFieldsRewrite() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var httpFieldsRewrite = HTTPFieldsRewrite()
      httpFieldsRewrite.direction = .request
      httpFieldsRewrite.pattern = "^http://example.com"
      httpFieldsRewrite.action = .remove
      httpFieldsRewrite.name = "Cookie"
      httpFieldsRewrite.value = ""
      httpFieldsRewrite.replacement = ""

      try """
      [HTTP Fields Rewrite]
      request ^http://example.com remove Cookie
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var newHTTPFieldsRewrite = HTTPFieldsRewrite()
      newHTTPFieldsRewrite.direction = .request
      newHTTPFieldsRewrite.pattern = "^http://example.com"
      newHTTPFieldsRewrite.action = .add
      newHTTPFieldsRewrite.name = "DNT"
      newHTTPFieldsRewrite.value = "1"
      newHTTPFieldsRewrite.replacement = ""

      await #expect(throws: Never.self) {
        try await profileAssistant.replace(httpFieldsRewrite, with: newHTTPFieldsRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [HTTP Fields Rewrite]
        request ^http://example.com add DNT 1
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func moveHTTPFieldsRewrites() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [HTTP Fields Rewrite]
      request ^http://example.com remove Cookie
      request ^http://example.com add DNT 1
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.moveHTTPFieldsRewrites(fromOffsets: IndexSet([1]), toOffset: 0)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [HTTP Fields Rewrite]
        request ^http://example.com add DNT 1
        request ^http://example.com remove Cookie
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func removeHTTPFieldsRewrites() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var httpFieldsRewrite = HTTPFieldsRewrite()
      httpFieldsRewrite.pattern = "(?:http://)?apple.com"
      try """
      [HTTP Fields Rewrite]
      request ^http://example.com remove Cookie
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.removeHTTPFieldsRewrites(atOffsets: IndexSet([0]))
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [HTTP Fields Rewrite]
        """
      #expect(finalize == expected)
    }
  }

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func removeSpecifiedHTTPFieldsRewrite() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var httpFieldsRewrite = HTTPFieldsRewrite()
      httpFieldsRewrite.direction = .request
      httpFieldsRewrite.pattern = "^http://example.com"
      httpFieldsRewrite.action = .add
      httpFieldsRewrite.name = "DNT"
      httpFieldsRewrite.value = "1"
      httpFieldsRewrite.replacement = ""

      try """
      [HTTP Fields Rewrite]
      request ^http://example.com add DNT 1
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.delete(httpFieldsRewrite)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [HTTP Fields Rewrite]
        """
      #expect(finalize == expected)
    }
  }
}
