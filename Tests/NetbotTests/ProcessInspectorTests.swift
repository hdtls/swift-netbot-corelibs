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

import NEAddressProcessing
import NetbotLiteData
import Testing

@testable import Netbot

struct ProcessInspectorTests {

  @available(SwiftStdlib 6.0, *)
  struct MockInspector: _ProcessInspector {
    let processName: String?
    func processInfo(address: UInt16) async throws -> Netbot.ProcessInfo? {
      #if os(macOS)
        let processInfo = Netbot.ProcessInfo()
      #else
        var processInfo = Netbot.ProcessInfo()
      #endif
      processInfo.processName = processName
      return processInfo
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func resolveProcessInfoWithNilSourceEndpoint() async {
    await #expect(throws: AnalyzeError.operationUnsupported) {
      let connection = Connection()
      let inspector = ProcessResolver(backing: MockInspector(processName: nil))
      _ = try await inspector.processInfo(connection: connection)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func resolveProcessInfoWithInvalidPortOfSourceEndpoint() async {
    await #expect(throws: AnalyzeError.operationUnsupported) {
      let url = URL(string: "http://123.123.123.13:\(Int.max)")!

      var establishmentReport = EstablishmentReport()
      establishmentReport.sourceEndpoint = .url(url)
      let connection = Connection()
      connection.establishmentReport = establishmentReport

      let inspector = ProcessResolver(backing: MockInspector(processName: nil))
      _ = try await inspector.processInfo(connection: connection)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func operationUnsupported() async {
    await #expect(throws: AnalyzeError.operationUnsupported) {
      var establishmentReport = EstablishmentReport()
      establishmentReport.sourceEndpoint = .hostPort(host: "123.123.123.123", port: 443)
      let connection = Connection()
      connection.establishmentReport = establishmentReport

      let inspector = ProcessResolver(backing: OperationUnsupportedProcessInspector())
      _ = try await inspector.processInfo(connection: connection)
    }
  }

  @available(SwiftStdlib 6.0, *)
  @Test func modifySourceEndpointIfWeHaveStoreNewAddress() async {
    var establishmentReport = EstablishmentReport()
    establishmentReport.sourceEndpoint = .hostPort(host: "123.123.123.123", port: 443)
    let connection = Connection()
    connection.establishmentReport = establishmentReport

    let sourceEndpoint = Address.hostPort(host: "172.23.42.3", port: 443)
    let inspector = ProcessResolver(backing: OperationUnsupportedProcessInspector())
    inspector.store(.hostPort(host: "123.123.123.123", port: 443), to: sourceEndpoint)
    _ = try? await inspector.processInfo(connection: connection)
    #expect(connection.establishmentReport?.sourceEndpoint == sourceEndpoint)
  }

  @available(SwiftStdlib 6.0, *)
  @Test(arguments: zip(["zsh", nil], ["zsh", "Unknown"]))
  func formatProcessLocalizedName(processName: String?, localizedName: String) async {
    var establishmentReport = EstablishmentReport()
    establishmentReport.sourceEndpoint = .hostPort(host: "123.123.123.123", port: 443)
    let connection = Connection()
    connection.establishmentReport = establishmentReport

    let inspector = ProcessResolver(backing: MockInspector(processName: processName))
    await #expect(throws: Never.self) {
      let processInfo = try await inspector.processInfo(connection: connection)
      #expect(processInfo.program?.localizedName == localizedName)
    }
  }
}
