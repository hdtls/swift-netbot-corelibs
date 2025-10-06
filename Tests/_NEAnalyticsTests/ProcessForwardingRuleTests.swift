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

import Anlzr
import AnlzrReports
import Testing

@testable import _NEAnalytics

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite(.tags(.forwardingRule))
struct ProcessForwardingRuleTests {

  @Test func processForwardingRulePropertyInitialValue() {
    let data = ProcessForwardingRule(processName: "ssh", forwardProtocol: .direct)
    #expect(data.processName == "ssh")
    #expect(data.description == "PROCESS-NAME ssh")
  }

  @Test func processForwardingRuleCopyOnWrite() {
    var a = ProcessForwardingRule(processName: "ssh", forwardProtocol: .direct)
    let b = a
    let c = a
    a.processName = "nsurlsessiond"
    #expect(b == c)
    #expect(b != a)
    #expect(c != a)
  }

  @Test func processForwardingRulePredicate() {
    let connection = Connection()
    connection.processReport = ProcessReport(
      processIdentifier: 12319,
      program: .init(
        localizedName: "nsurlsessiond", bundleURL: nil,
        executableURL: URL(filePath: "/usr/libexec/nsurlsessiond"), iconTIFFRepresentation: nil)
    )

    let forwardingRule = ProcessForwardingRule(
      processName: "nsurlsessiond", forwardProtocol: .direct)
    #expect(throws: Never.self) {
      let result = try forwardingRule.predicate(connection)
      #expect(result)
    }
  }

  @Test func processForwardingRuleEquatableConformance() async throws {
    let lhs = ProcessForwardingRule(processName: "trustd", forwardProtocol: .direct)
    let rhs = ProcessForwardingRule(processName: "nsurlsessiond", forwardProtocol: .direct)
    #expect(lhs != rhs)
    let rhs1 = ProcessForwardingRule(processName: "trustd", forwardProtocol: .reject)
    #expect(lhs != rhs1)
    let rhs2 = ProcessForwardingRule(processName: "nsurlsessiond", forwardProtocol: .reject)
    #expect(lhs != rhs2)
  }
}
