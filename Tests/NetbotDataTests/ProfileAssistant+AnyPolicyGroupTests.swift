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

@Suite(.tags(.profileAssistant)) struct AnyProxyGroupManagementTests {

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
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
