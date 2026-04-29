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

import HTTPTypes
import NetbotLite
import NetbotLiteData
import Testing

@testable import Netbot

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.forwardingRule))
struct DomainsetForwardingRuleTests {

  private let externalResourceDirectory: URL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().appending(path: "External Resource")

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func propertyInitialValue() {
    let data = DomainsetForwardingRule(
      originalURLString: #filePath, forwardProtocol: .direct)
    #expect(data.originalURLString == #filePath)
    #expect(data.externalDomains.isEmpty)
    #expect(data.description == "DOMAIN-SET DomainsetForwardingRuleTests.swift")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func externalResourceDoesNotExists() async throws {
    let data = DomainsetForwardingRule(
      originalURLString: #filePath, forwardProtocol: .direct)
    #expect(data.originalURLString == #filePath)
    #expect(data.externalDomains.isEmpty)
    #expect(data.description == "DOMAIN-SET DomainsetForwardingRuleTests.swift")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func externalDomainsProcessing() async throws {
    let forwardingRule = DomainsetForwardingRule(
      externalResourceDirectory: externalResourceDirectory,
      originalURLString: "https://example.com/domains", forwardProtocol: .direct)
    #expect(forwardingRule.originalURLString == "https://example.com/domains")
    #expect(!forwardingRule.externalDomains.isEmpty)
    #expect(forwardingRule.externalDomains == ["test1.com", ".test2.com"])
    #expect(forwardingRule.description == "DOMAIN-SET domains")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func setOriginalURLString() async throws {
    var forwardingRule = DomainsetForwardingRule(
      externalResourceDirectory: externalResourceDirectory, originalURLString: #filePath,
      forwardProtocol: .direct)
    #expect(forwardingRule.originalURLString == #filePath)
    #expect(forwardingRule.externalDomains.isEmpty)
    #expect(forwardingRule.description == "DOMAIN-SET DomainsetForwardingRuleTests.swift")

    forwardingRule.originalURLString = "https://example.com/domains"
    #expect(forwardingRule.originalURLString == "https://example.com/domains")
    #expect(!forwardingRule.externalDomains.isEmpty)
    #expect(forwardingRule.externalDomains == ["test1.com", ".test2.com"])
    #expect(forwardingRule.description == "DOMAIN-SET domains")
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func copyOnWrite() {
    var a = DomainsetForwardingRule(
      externalResourceDirectory: externalResourceDirectory, originalURLString: #filePath,
      forwardProtocol: .direct)
    let b = a
    let c = a
    a.originalURLString = "https://example.com/domains"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test(arguments: ["test1.com:443", "sub.test2.com", "test2.com:443"])
  func predicateWorks(_ authority: String) {
    let connection = Connection()
    connection.originalRequest = .init(
      httpRequest: .init(method: .connect, scheme: "https", authority: authority, path: nil))

    let forwardingRule = DomainsetForwardingRule(
      externalResourceDirectory: externalResourceDirectory,
      originalURLString: "https://example.com/domains", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      _ = try forwardingRule.predicate(connection)
    }
  }

  #if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    @available(SwiftStdlib 5.5, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @Test func equatableConformance() {
    let lhs = DomainsetForwardingRule(
      originalURLString: "https://test1.com/domains", forwardProtocol: .direct)
    let rhs = DomainsetForwardingRule(
      originalURLString: "https://test2.com/domains", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = DomainsetForwardingRule(
      originalURLString: "https://test1.com/domains", forwardProtocol: .direct)
    #expect(lhs == rhs1)
    let rhs2 = DomainsetForwardingRule(
      originalURLString: "https://test1.com/domains", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
