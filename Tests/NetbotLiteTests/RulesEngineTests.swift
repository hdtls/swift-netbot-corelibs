// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import Logging
import NEAddressProcessing
import NIOCore
import NetbotDNS
import NetbotLiteData
import Testing

@testable import NetbotLite

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Network)
  import NIOTransportServices
#else
  import NIOPosix
#endif

@Suite struct RulesEngineTests {

  @available(SwiftStdlib 6.0, *)
  @Test func setForwardingRules() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    #expect(service.forwardingRules.isEmpty)
    #expect(service.cache.isEmpty)

    service.setForwardingRules([_FinalForwardingRule()])
    #expect(service.forwardingRules.count == 1)
    #expect(service.cache.isEmpty)

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))
    _ = await service.executeAllRules(connection: connection)
    #expect(service.forwardingRules.count == 1)
    #expect(!service.cache.isEmpty)

    service.setForwardingRules([_FinalForwardingRule()])
    #expect(service.forwardingRules.count == 1)
    // Set new rules should invalidate all cache.
    #expect(service.cache.isEmpty)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func ruleLookupWithoutCache() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([_FinalForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))
    let result = await service.executeAllRules(connection: connection)
    #expect(result._forwardingRule is _FinalForwardingRule)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func ruleLookupWithCache() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([_FinalForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))
    // We need cache lookup for first request.
    _ = await service.executeAllRules(connection: connection)

    // The seconds lookup should use cache directly.
    let result = await service.executeAllRules(connection: connection)

    #expect(result._forwardingRule is _FinalForwardingRule)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func ruleLookupForConnectionThatOriginalRequestIsNil() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([_FinalForwardingRule()])

    let connection = Connection()
    #expect(connection.originalRequest == nil)
    let result = await service.executeAllRules(connection: connection)

    #expect(result._forwardingRule is _FinalForwardingRule)
    #expect(result.duration > .zero)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func inFlightTaskWorks() async throws {
    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([_FinalForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))
    async let r1 = await service.executeAllRules(connection: connection)
    async let r2 = await service.executeAllRules(connection: connection)

    _ = await [r1, r2]
  }

  @available(SwiftStdlib 6.0, *)
  @Test func ruleLookupFallbackWorks() async throws {
    struct MockForwardingRule: ForwardingRule, ForwardingRuleConvertible {

      var forwardProtocol: any ForwardProtocolConvertible { .direct }

      var description: String { "DOMAIN" }

      func predicate(_ connection: NetbotLiteData.Connection) throws -> Bool {
        false
      }
    }

    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([MockForwardingRule(), MockForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))

    let result = await service.executeAllRules(connection: connection)
    #expect(result._forwardingRule is FinalForwardingRule)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func replaceBuiltinFinalRuleWithCustomizedFinalRule() async throws {
    struct MockForwardingRule: FinalForwardingRule, ForwardingRuleConvertible {
      var forwardProtocol: any ForwardProtocolConvertible { .reject }
    }

    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([MockForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))

    let result = await service.executeAllRules(connection: connection)
    #expect(result._forwardingRule is MockForwardingRule)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "REJECT")
  }

  @available(SwiftStdlib 6.0, *)
  @Test func ruleMatchingFailedWhenRuleLookup() async throws {
    struct MockForwardingRule: ForwardingRule, ForwardingRuleConvertible {

      var forwardProtocol: any ForwardProtocolConvertible { .direct }

      var description: String { "DOMAIN" }

      func predicate(_ connection: NetbotLiteData.Connection) throws -> Bool {
        throw CancellationError()
      }
    }

    let service = DefaultRulesEngine(logger: .init(label: ""))
    service.setForwardingRules([MockForwardingRule(), _FinalForwardingRule()])

    let connection = Connection()
    connection.originalRequest = .init(address: .hostPort(host: "198.51.100.1", port: 80))

    let result = await service.executeAllRules(connection: connection)
    #expect(result._forwardingRule is FinalForwardingRule)
    #expect(result.forwardingRule == "FINAL")
    #expect(result.forwardProtocol == "DIRECT")
  }
}
