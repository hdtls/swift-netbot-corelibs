//
// See LICENSE.txt for license information
//

import Testing

@testable import NetbotData

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import struct Foundation.IndexSet
#else
  import Foundation
#endif

@Suite(.tags(.profileAssistant)) struct AnyProxyManagementTests {

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertProxyIntoProfileFile() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy]
      DIRECT = direct
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var proxy = AnyProxy(name: "Test Insert")
      proxy.kind = .direct
      await #expect(throws: Never.self) {
        try await profileAssistant.insert(proxy)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy]
        DIRECT = direct
        Test Insert = direct
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertAnyProxyIntoProfileWhereAnyProxiesSectionExists() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try "".write(to: profileURL, atomically: true, encoding: .utf8)

      var proxy = AnyProxy(name: "Test Insert")
      proxy.kind = .direct
      await #expect(throws: Never.self) {
        try await profileAssistant.insert(proxy)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """

        [Proxy]
        Test Insert = direct
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertAnyProxyIntoProfileWhereAnyProxiesSectionExistsAndItemsNotEmpty() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy]
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var proxy = AnyProxy(name: "Test Insert")
      proxy.kind = .direct
      await #expect(throws: Never.self) {
        try await profileAssistant.insert(proxy)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy]
        Test Insert = direct
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func insertAnyProxyIntoProfileWhereAnyProxiesSectionAtMiddleOfProfile() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [DNS Mapping]
      recovery.com = server:8.8.8.8
      [Proxy]
      DIRECT = direct
      [Rule]
      DOMAIN-SUFFIX, swift.org, DIRECT
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var newProxy = AnyProxy(name: "HTTP")
      newProxy.serverAddress = "127.0.0.1"
      newProxy.port = 8080
      newProxy.kind = .http
      await #expect(throws: Never.self) {
        try await profileAssistant.insert(newProxy)
      }

      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [DNS Mapping]
        recovery.com = server:8.8.8.8
        [Proxy]
        DIRECT = direct
        HTTP = http, port = 8080, server-address = 127.0.0.1
        [Rule]
        DOMAIN-SUFFIX, swift.org, DIRECT
        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func replaceProxyWithNewProxy() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy]
      HTTP = http

      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var proxy = AnyProxy(name: "HTTP")
      proxy.kind = .http

      var newProxy = AnyProxy(name: "HTTP")
      newProxy.serverAddress = "127.0.0.1"
      newProxy.port = 8080
      newProxy.kind = .http

      await #expect(throws: Never.self) {
        try await profileAssistant.replace(proxy, with: newProxy)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy]
        HTTP = http, port = 8080, server-address = 127.0.0.1

        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func replaceProxyWithNewProxyWhichNameAlsoChanged() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy]
      DIRECT = direct

      [Policy Group]
      PROXY = select, proxies = DIRECT

      [Rule]
      DOMAIN-SUFFIX,example.com,DIRECT

      """.write(to: profileURL, atomically: true, encoding: .utf8)

      var proxy = AnyProxy(name: "DIRECT")
      proxy.kind = .direct

      var newProxy = AnyProxy(name: "HTTP1")
      newProxy.kind = .direct

      await #expect(throws: Never.self) {
        try await profileAssistant.replace(proxy, with: newProxy)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy]
        HTTP1 = direct

        [Policy Group]
        PROXY = select, proxies = HTTP1

        [Rule]
        DOMAIN-SUFFIX,example.com,HTTP1

        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func moveProxies() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy]
      DIRECT = direct
      REJECT = reject
      REJECT-TINYGIF = reject-tinygif
      HTTP = http, port = 8000, server-address = 127.0.0.1

      [Policy Group]
      PROXY = select, proxies = DIRECT, REJECT, REJECT-TINYGIF, HTTP

      [Rule]
      DOMAIN-SUFFIX,example.com,DIRECT

      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.moveProxies(fromOffsets: IndexSet([2]), toOffset: 1)
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy]
        DIRECT = direct
        REJECT-TINYGIF = reject-tinygif
        REJECT = reject
        HTTP = http, port = 8000, server-address = 127.0.0.1

        [Policy Group]
        PROXY = select, proxies = DIRECT, REJECT, REJECT-TINYGIF, HTTP

        [Rule]
        DOMAIN-SUFFIX,example.com,DIRECT

        """
      #expect(finalize == expected)
    }
  }

  @available(swift 5.9)
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  @Test func removeProxies() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL

      try """
      [Proxy]
      DIRECT = direct
      REJECT = reject
      REJECT-TINYGIF = reject-tinygif
      HTTP = http, port = 8000, server-address = 127.0.0.1

      [Policy Group]
      PROXY = select, proxies = DIRECT, REJECT, REJECT-TINYGIF, HTTP

      [Rule]
      DOMAIN-SUFFIX,example.com,DIRECT

      """.write(to: profileURL, atomically: true, encoding: .utf8)

      await #expect(throws: Never.self) {
        try await profileAssistant.removeProxies(atOffsets: IndexSet([0, 2]))
      }
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      let expected = """
        [Proxy]
        REJECT = reject
        HTTP = http, port = 8000, server-address = 127.0.0.1

        [Policy Group]
        PROXY = select, proxies = REJECT, REJECT-TINYGIF, HTTP

        [Rule]

        """
      #expect(finalize == expected)
    }
  }
}
