//
// See LICENSE.txt for license information
//

import Testing
import _ResourceProcessing

@testable import Netbot

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import struct Foundation.IndexSet
#else
  import Foundation
#endif

@Suite(.tags(.profileAssistant, .forwardingRule))
struct AnyForwardingRuleManagementTests {

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertRule() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var forwardingRule = AnyForwardingRule()
      forwardingRule.kind = .domainSuffix
      forwardingRule.value = "swift.org"
      forwardingRule.foreignKey = "DIRECT"

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(forwardingRule)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """

        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertAnyRuleIntoProfileWhereAnyRulesSectionExists() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Rule]
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var forwardingRule = AnyForwardingRule()
      forwardingRule.kind = .domainSuffix
      forwardingRule.value = "swift.org"
      forwardingRule.foreignKey = "DIRECT"

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(forwardingRule)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertAnyRuleIntoProfileWhereAnyRulesSectionExistsAndItemsNotEmpty() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Rule]
      DOMAIN-KEYWORD, swift, DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var forwardingRule = AnyForwardingRule()
      forwardingRule.kind = .domainSuffix
      forwardingRule.value = "swift.org"
      forwardingRule.foreignKey = "DIRECT"

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(forwardingRule)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        DOMAIN-KEYWORD, swift, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertAnyRuleIntoProfileWhereAnyRulesSectionAtMiddleOfProfile() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Policies]
      DIRECT,direct
      [Rule]
      GEOIP, CN, DIRECT
      [DNS Mapping]
      example.com = 1.1.1.1
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var forwardingRule = AnyForwardingRule()
      forwardingRule.kind = .domainSuffix
      forwardingRule.value = "swift.org"
      forwardingRule.foreignKey = "DIRECT"

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(forwardingRule)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Policies]
        DIRECT,direct
        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        GEOIP, CN, DIRECT
        [DNS Mapping]
        example.com = 1.1.1.1
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func replaceRule() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var forwardingRule = AnyForwardingRule()
      forwardingRule.kind = .domainKeyword
      forwardingRule.value = "swift"
      forwardingRule.foreignKey = "DIRECT"

      try """
      [Rule]
      DOMAIN-KEYWORD, swift, DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var newRule = AnyForwardingRule()
      newRule.kind = .domainSuffix
      newRule.value = "swift.org"
      newRule.foreignKey = "DIRECT"

      await #expect(throws: Never.self) {
        try await profileAssistant.replace(forwardingRule, with: newRule)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func moveRules() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Rule]
      DOMAIN-KEYWORD, swift, DIRECT
      DOMAIN-SUFFIX, swift.org, DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.moveRules(fromOffsets: IndexSet([1]), toOffset: 0)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        DOMAIN-KEYWORD, swift, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func removeRules() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Rule]
      DOMAIN-KEYWORD, swift, DIRECT
      DOMAIN-SUFFIX, swift.org, DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.removeRules(atOffsets: IndexSet([0]))
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func removeSpecifiedRule() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var forwardingRule = AnyForwardingRule()
      forwardingRule.kind = .domainKeyword
      forwardingRule.value = "swift"
      forwardingRule.foreignKey = "DIRECT"

      try """
      [Rule]
      DOMAIN-KEYWORD, swift, DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.delete(forwardingRule)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Rule]
        """
      #expect(finalize == expected)
    }
  }
}
