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

@Suite(.tags(.profileAssistant)) struct DNSMappingManagementTests {

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertDNSMapping() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      let mapping = DNSMapping(domainName: "example.com", value: "1.1.1.1")
      await #expect(throws: Never.self) {
        try await profileAssistant.insert(mapping)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """

        [DNS Mapping]
        example.com = 1.1.1.1
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertDNSMappingIntoProfileWhereDNSMappingsSectionExists() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try "[DNS Mapping]".write(to: profileURL, atomically: true, encoding: .utf8)

      let mapping = DNSMapping(domainName: "example.com", value: "1.1.1.1")
      await #expect(throws: Never.self) {
        try await profileAssistant.insert(mapping)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [DNS Mapping]
        example.com = 1.1.1.1
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertDNSMappingIntoProfileWhereDNSMappingsSectionExistsAndItemsNotEmpty() async throws
  {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [DNS Mapping]
      recovery.com = server:8.8.8.8
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      let mapping = DNSMapping(domainName: "example.com", value: "1.1.1.1")
      await #expect(throws: Never.self) {
        try await profileAssistant.insert(mapping)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [DNS Mapping]
        recovery.com = server:8.8.8.8
        example.com = 1.1.1.1
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertDNSMappingIntoProfileWhereDNSMappingsSectionAtMiddleOfProfile() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Policies]
      DIRECT,direct
      [DNS Mapping]
      recovery.com = server:8.8.8.8
      [Rule]
      DOMAIN-SUFFIX, swift.org, DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      let mapping = DNSMapping(domainName: "example.com", value: "1.1.1.1")
      await #expect(throws: Never.self) {
        try await profileAssistant.insert(mapping)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Policies]
        DIRECT,direct
        [DNS Mapping]
        recovery.com = server:8.8.8.8
        example.com = 1.1.1.1
        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func replaceDNSMapping() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [DNS Mapping]
      recovery.com = server:8.8.8.8
      """.write(to: profileURL, atomically: true, encoding: .utf8)
      var mapping = DNSMapping(domainName: "recovery.com", value: "8.8.8.8")
      mapping.kind = .dns
      let newMapping = DNSMapping(domainName: "example.com", value: "1.1.1.1")
      await #expect(throws: Never.self) {
        try await profileAssistant.replace(mapping, with: newMapping)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [DNS Mapping]
        example.com = 1.1.1.1
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func removeDNSMapping() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [DNS Mapping]
      recovery.com = server:8.8.8.8
      """.write(to: profileURL, atomically: true, encoding: .utf8)
      var mapping = DNSMapping(domainName: "recovery.com", value: "8.8.8.8")
      mapping.kind = .dns
      await #expect(throws: Never.self) {
        try await profileAssistant.delete(mapping)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [DNS Mapping]
        """
      #expect(finalize == expected)
    }
  }
}
