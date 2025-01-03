//
// See LICENSE.txt for license information
//

import Testing

@testable import Netbot

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import struct Foundation.IndexSet
#else
  import Foundation
#endif

@Suite(.tags(.urlRewrite))
struct URLRewriteManagementTests {

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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
