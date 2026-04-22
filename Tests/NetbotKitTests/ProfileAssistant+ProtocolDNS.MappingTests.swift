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

@Suite(.tags(.profileAssistant))
struct ProfileAsistant__ProtocolDNS_MappingTests {

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertDNSMapping() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      let mapping = ProtocolDNS.Mapping(domainName: "example.com", value: "1.1.1.1")
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertDNSMappingIntoProfileWhereDNSMappingsSectionExists() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try "[DNS Mapping]".write(to: profileURL, atomically: true, encoding: .utf8)

      let mapping = ProtocolDNS.Mapping(domainName: "example.com", value: "1.1.1.1")
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func insertDNSMappingIntoProfileWhereDNSMappingsSectionExistsAndItemsNotEmpty() async throws
  {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [DNS Mapping]
      recovery.com = server:8.8.8.8
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      let mapping = ProtocolDNS.Mapping(domainName: "example.com", value: "1.1.1.1")
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

      let mapping = ProtocolDNS.Mapping(domainName: "example.com", value: "1.1.1.1")
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func replaceDNSMapping() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [DNS Mapping]
      recovery.com = server:8.8.8.8
      """.write(to: profileURL, atomically: true, encoding: .utf8)
      var mapping = ProtocolDNS.Mapping(domainName: "recovery.com", value: "8.8.8.8")
      mapping.strategy = .dns
      let newMapping = ProtocolDNS.Mapping(domainName: "example.com", value: "1.1.1.1")
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func removeDNSMapping() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [DNS Mapping]
      recovery.com = server:8.8.8.8
      """.write(to: profileURL, atomically: true, encoding: .utf8)
      var mapping = ProtocolDNS.Mapping(domainName: "recovery.com", value: "8.8.8.8")
      mapping.strategy = .dns
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
