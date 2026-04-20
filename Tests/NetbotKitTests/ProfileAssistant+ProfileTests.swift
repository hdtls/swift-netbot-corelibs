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

import Logging
import Testing

@testable import NetbotKit

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.profileAssistant)) struct ProfileManagementTests {

  @available(SwiftStdlib 5.9, *)
  @Test func replaceUnsupportedProperties() async throws {
    try await withManagedProfile { profileAssistant in
      await XCTAssertNoThrow(try await profileAssistant.replace(\.lazyProxies, with: []))
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == "")
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceMatchedPropertyToSameValue() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL
      let expected = """
        [General]
        log-level = info
        """

      try expected.write(to: profileURL, atomically: true, encoding: .utf8)
      try await profileAssistant.replace(\.logLevel, with: .info)
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceMatchedPropertyToNewValue() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL
      let expected = """
        [General]
        log-level = debug
        """

      try """
      [General]
      log-level = info
      """.write(to: profileURL, atomically: true, encoding: .utf8)

      try await profileAssistant.replace(\.logLevel, with: .debug)
      let finalize = try String(contentsOf: profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceUndefindGeneralProperties() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL
      let expected = """
        [General]
        log-level = debug
        [group]

        """

      try """
      [group]

      """.write(to: profileURL, atomically: true, encoding: .utf8)
      try await profileAssistant.replace(\.logLevel, with: .debug)
      var finalize = try String(contentsOf: profileURL, encoding: .utf8)
      #expect(finalize == expected)

      try """
      [General]
      [group]

      """.write(to: profileURL, atomically: true, encoding: .utf8)
      try await profileAssistant.replace(\.logLevel, with: .debug)
      finalize = try String(contentsOf: profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceUndefinedMitMProperties() async throws {
    try await withManagedProfile { profileAssistant in
      let profileURL = await profileAssistant.profileURL
      let expected = """
        [group]

        [MitM]
        passphrase = ADFEIFMLDI
        """

      try """
      [group]

      """.write(to: profileURL, atomically: true, encoding: .utf8)
      try await profileAssistant.replace(\.passphrase, with: "ADFEIFMLDI")
      var finalize = try String(contentsOf: profileURL, encoding: .utf8)
      #expect(finalize == expected)

      try """
      [group]

      [MitM]
      """.write(to: profileURL, atomically: true, encoding: .utf8)
      try await profileAssistant.replace(\.passphrase, with: "ADFEIFMLDI")
      finalize = try String(contentsOf: profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func repaceDNSServers() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """
        [General]
        dns-servers = 1.1.1.1,2.2.2.2

        """

      try await profileAssistant.replace(\.dnsSettings.servers, with: ["1.1.1.1", "2.2.2.2"])
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceExceptions() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """
        [General]
        exceptions = 1.1.1.1

        """

      try await profileAssistant.replace(\.exceptions, with: ["1.1.1.1"])
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceHTTPListenAddress() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """
        [General]
        http-listen-address = 1.1.1.1

        """

      try await profileAssistant.replace(\.httpListenAddress, with: "1.1.1.1")
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceHTTPListenPort() async throws {
    try await withManagedProfile { profileAssistant in
      var expected = """
        [General]
        http-listen-port = 8080

        """

      try await profileAssistant.replace(\.httpListenPort, with: 8080)
      var finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)

      expected = """
        [General]

        """

      try await profileAssistant.replace(\.httpListenPort, with: nil)
      finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceSOCKSListenAddress() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """
        [General]
        socks-listen-address = 1.1.1.1

        """

      try await profileAssistant.replace(\.socksListenAddress, with: "1.1.1.1")
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceSOCKSListenPort() async throws {
    try await withManagedProfile { profileAssistant in
      var expected = """
        [General]
        socks-listen-port = 8080

        """

      try await profileAssistant.replace(\.socksListenPort, with: 8080)
      var finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)

      expected = """
        [General]

        """

      try await profileAssistant.replace(\.socksListenPort, with: nil)
      finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceExcludeSimpleHostnames() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """
        [General]
        exclude-simple-hostnames = true

        """

      try await profileAssistant.replace(\.excludeSimpleHostnames, with: true)
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceSkipCertificateVerification() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """

        [MitM]
        skip-certificate-verification = true
        """

      try await profileAssistant.replace(\.skipCertificateVerification, with: true)
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceHostnames() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """

        [MitM]
        hostnames = 1.1.1.1
        """

      try await profileAssistant.replace(\.hostnames, with: ["1.1.1.1"])
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceBase64EncodedP12String() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """

        [MitM]
        base64-encoded-p12 = LDSJFIOEJFMDKLFMLSDF
        """

      try await profileAssistant.replace(\.base64EncodedP12String, with: "LDSJFIOEJFMDKLFMLSDF")
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replacePassphrase() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """

        [MitM]
        passphrase = 8080
        """

      try await profileAssistant.replace(\.passphrase, with: "8080")
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceTestURL() async throws {
    try await withManagedProfile { profileAssistant in
      var expected = """
        [General]
        test-url = http://test.example.com

        """

      try await profileAssistant.replace(\.testURL, with: URL(string: "http://test.example.com"))
      var finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)

      expected = """
        [General]

        """

      try await profileAssistant.replace(\.testURL, with: nil)
      finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceProxyTestURL() async throws {
    try await withManagedProfile { profileAssistant in
      var expected = """
        [General]
        proxy-test-url = http://test.example.com

        """

      try await profileAssistant.replace(
        \.proxyTestURL, with: URL(string: "http://test.example.com"))
      var finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)

      expected = """
        [General]

        """

      try await profileAssistant.replace(\.proxyTestURL, with: nil)
      finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceTestTimeout() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """
        [General]
        test-timeout = 5.0

        """

      try await profileAssistant.replace(\.testTimeout, with: 5.0)
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceDontAlertRejectErrors() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """
        [General]
        dont-alert-reject-errors = true

        """

      try await profileAssistant.replace(\.dontAlertRejectErrors, with: true)
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }

  @available(SwiftStdlib 5.9, *)
  @Test func replaceDontAllowRemoteAccess() async throws {
    try await withManagedProfile { profileAssistant in
      let expected = """
        [General]
        dont-allow-remote-access = true

        """

      try await profileAssistant.replace(\.dontAllowRemoteAccess, with: true)
      let finalize = try await String(contentsOf: profileAssistant.profileURL, encoding: .utf8)
      #expect(finalize == expected)
    }
  }
}
