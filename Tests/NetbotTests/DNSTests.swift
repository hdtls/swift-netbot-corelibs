//
// See LICENSE.txt for license information
//

#if canImport(SwiftData)
  import SwiftData
  import Testing

  @testable import Netbot

  @Suite(.tags(.dns))
  struct DNSTests {
    private var recovery: String = """
      [General]
      dns-servers = 192.168.0.1, 8.8.8.8

      """

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func setDNSServers() async throws {
      try await withManagedProfile { profileAssistant in
        let profileURL = await profileAssistant.profileURL
        try recovery.write(to: profileURL, atomically: true, encoding: .utf8)
        await #expect(throws: Never.self) {
          try await profileAssistant.replace(\.dnsSettings.servers, with: [])
        }
        var finalize = try String(contentsOf: profileURL, encoding: .utf8)
        var expected = """
          [General]

          """
        #expect(finalize == expected)

        await #expect(throws: Never.self) {
          try await profileAssistant.replace(
            \.dnsSettings.servers, with: ["8.8.8.8, 4.4.4.4, 1.1.1.1"])
        }
        finalize = try String(contentsOf: profileURL, encoding: .utf8)
        expected = """
          [General]
          dns-servers = 8.8.8.8, 4.4.4.4, 1.1.1.1

          """
        #expect(finalize == expected)
      }
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func removeDNSServer() async throws {
      try await withManagedProfile { profileAssistant in
        let profileURL = await profileAssistant.profileURL

        try recovery.write(to: profileURL, atomically: true, encoding: .utf8)
        await #expect(throws: Never.self) {
          try await profileAssistant.removeDNSServer("192.168.0.1")
        }
        let finalize = try String(contentsOf: profileURL, encoding: .utf8)
        let expected = """
          [General]
          dns-servers = 8.8.8.8

          """
        #expect(finalize == expected)
      }
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func removeDNSServerThatDoseNotExistInProfileFile() async throws {
      try await withManagedProfile { profileAssistant in
        let profileURL = await profileAssistant.profileURL

        try recovery.write(to: profileURL, atomically: true, encoding: .utf8)
        await #expect(throws: Never.self) {
          try await profileAssistant.removeDNSServer("1.1.1.1")
        }
        let finalize = try String(contentsOf: profileURL, encoding: .utf8)
        let expected = """
          [General]
          dns-servers = 192.168.0.1, 8.8.8.8

          """
        #expect(finalize == expected)
      }
    }

    @available(swift 5.9)
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    @Test func removeDNSServersAtSpecifiedOffsets() async throws {
      try await withManagedProfile { profileAssistant in
        let profileURL = await profileAssistant.profileURL

        try recovery.write(to: profileURL, atomically: true, encoding: .utf8)
        await #expect(throws: Never.self) {
          try await profileAssistant.removeDNSServers(atOffsets: .init(integer: 1))
        }
        let finalize = try String(contentsOf: profileURL, encoding: .utf8)
        let expected = """
          [General]
          dns-servers = 192.168.0.1

          """
        #expect(finalize == expected)
      }
    }
  }
#endif
