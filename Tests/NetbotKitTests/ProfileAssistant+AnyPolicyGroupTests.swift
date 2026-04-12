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

@testable import NetbotKit

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import struct Foundation.IndexSet
#else
  import Foundation
#endif

@Suite(.tags(.profileAssistant)) struct AnyProxyGroupManagementTests {

  @available(SwiftStdlib 5.9, *)
  @Test func insertAnyProxyGroup() async throws {
    try await withManagedProfile { profileAssistant in
      var proxyGroup = AnyProxyGroup(name: "PROXY")
      proxyGroup.lazyProxies = ["DIRECT"]

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(proxyGroup)
      }

      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      let expected = """

        [Proxy Group]
        PROXY = select, proxies = DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func insertAnyProxyGroupIntoProfileWhereAnyProxyGroupsSectionExists() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy Group]
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var proxyGroup = AnyProxyGroup(name: "PROXY")
      proxyGroup.lazyProxies = ["DIRECT"]

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(proxyGroup)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy Group]
        PROXY = select, proxies = DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func insertAnyProxyGroupIntoProfileWhereAnyProxyGroupsSectionExistsAndItemsNotEmpty()
    async throws
  {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy Group]
      BUILTIN = select, proxies = direct, reject, reject-tinygif
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var proxyGroup = AnyProxyGroup(name: "PROXY")
      proxyGroup.lazyProxies = ["DIRECT"]

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(proxyGroup)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy Group]
        BUILTIN = select, proxies = direct, reject, reject-tinygif
        PROXY = select, proxies = DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func insertAnyProxyGroupIntoProfileWhereAnyProxyGroupsSectionAtMiddleOfProfile()
    async throws
  {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy]
      DIRECT,direct
      [Proxy Group]
      BUILTIN = select, proxies = direct, reject, reject-tinygif
      [DNS Mapping]
      example.com = 1.1.1.1
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var proxyGroup = AnyProxyGroup(name: "PROXY")
      proxyGroup.lazyProxies = ["DIRECT"]

      await #expect(throws: Never.self) {
        try await profileAssistant.insert(proxyGroup)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy]
        DIRECT,direct
        [Proxy Group]
        BUILTIN = select, proxies = direct, reject, reject-tinygif
        PROXY = select, proxies = DIRECT
        [DNS Mapping]
        example.com = 1.1.1.1
        """
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceAnyProxyGroup() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var proxyGroup = AnyProxyGroup(name: "PROXY")
      proxyGroup.lazyProxies = ["direct", "reject", "reject-tinygif"]
      try """
      [Proxy Group]
      PROXY = select, proxies = direct, reject, reject-tinygif
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var newPolicyGroup = AnyProxyGroup(name: "PROXY")
      newPolicyGroup.lazyProxies = ["DIRECT"]

      await #expect(throws: Never.self) {
        try await profileAssistant.replace(proxyGroup, with: newPolicyGroup)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy Group]
        PROXY = select, proxies = DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func policyGroupReferencedByTheRule() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      var proxyGroup = AnyProxyGroup(name: "BUILTIN")
      proxyGroup.lazyProxies = ["direct", "reject", "reject-tinygif"]
      try """
      [Proxy Group]
      BUILTIN = select, proxies = direct, reject, reject-tinygif

      [Rule]
      DOMAIN-SUFFIX,example.com,BUILTIN
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var newPolicyGroup = AnyProxyGroup(name: "PROXY")
      newPolicyGroup.lazyProxies = ["DIRECT"]

      await #expect(throws: Never.self) {
        try await profileAssistant.replace(proxyGroup, with: newPolicyGroup)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy Group]
        PROXY = select, proxies = DIRECT

        [Rule]
        DOMAIN-SUFFIX,example.com,PROXY
        """
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func moveAnyProxyGroups() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy Group]
      BUILTIN = select, proxies = direct, reject, reject-tinygif
      PROXY = select, proxies = DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.movePolicyGroups(fromOffsets: IndexSet([1]), toOffset: 0)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy Group]
        PROXY = select, proxies = DIRECT
        BUILTIN = select, proxies = direct, reject, reject-tinygif
        """
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func removeAnyProxyGroups() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy Group]
      BUILTIN = select, proxies = direct, reject, reject-tinygif
      PROXY = select, proxies = DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.removePolicyGroups(atOffsets: IndexSet([0]))
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy Group]
        PROXY = select, proxies = DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func removeSpecifiedAnyProxyGroup() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy Group]
      PROXY = select, proxies = DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var proxyGroup = AnyProxyGroup(name: "PROXY")
      proxyGroup.lazyProxies = ["DIRECT"]

      await #expect(throws: Never.self) {
        try await profileAssistant.delete(proxyGroup)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy Group]
        """
      #expect(finalize == expected)
    }
  }
}
