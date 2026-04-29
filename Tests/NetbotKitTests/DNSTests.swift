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

#if canImport(SwiftData)
  import SwiftData
  import Testing

  @testable import NetbotKit
  import Foundation

  @Suite(.tags(.dns))
  struct DNSTests {
    private var recovery: String = """
      [General]
      dns-servers = 192.168.0.1, 8.8.8.8

      """

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
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

    #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
      @available(SwiftStdlib 5.9, *)
    #else
      @available(SwiftStdlib 6.0, *)
    #endif
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
