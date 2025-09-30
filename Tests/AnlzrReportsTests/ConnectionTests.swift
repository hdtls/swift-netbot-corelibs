//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import HTTPTypes
import NEAddressProcessing
import Testing

@testable import AnlzrReports

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@Suite struct ConnectionTests {

  @available(SwiftStdlib 5.3, *)
  @Test func propertyInitialValues() {
    let connection = Connection()
    #expect(connection.originalRequest == nil)
    #expect(connection.currentRequest == nil)
    #expect(connection.taskDescription == "")
    #expect(connection.tls == false)
    #expect(connection.state == .establishing)
    #expect(connection.establishmentReport == nil)
    #expect(connection.forwardingReport == nil)
    #expect(connection.dataTransferReport == nil)
    #expect(connection.processReport == nil)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func incrementTaskIdentifier() {
    let c1 = Connection()

    let c2 = Connection()
    #expect(c2.taskIdentifier > c1.taskIdentifier)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func setOriginalRequest() {
    let originalRequest = Request(address: .hostPort(host: "example.com", port: 443))
    let connection = Connection()
    #expect(connection.originalRequest == nil)
    #expect(connection.currentRequest == nil)
    connection.originalRequest = originalRequest
    #expect(connection.currentRequest == originalRequest)
    connection.originalRequest = nil
    #expect(connection.originalRequest == nil)
    #expect(connection.currentRequest == originalRequest)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func identifiableConformance() async throws {
    let c = Connection()
    #expect(c.id == c.taskIdentifier)
  }

  @available(SwiftStdlib 5.3, *)
  @Test func codableConformance() throws {
    let connection = Connection(taskIdentifier: 6)
    connection.originalRequest = .init(address: .hostPort(host: "192.168.1.2", port: 63532))
    connection.currentRequest = .init(
      httpRequest: HTTPRequest.init(
        method: .get, scheme: "http", authority: "192.168.1.2:63532", path: nil)
    )
    connection.response = .init(httpResponse: .init(status: .badRequest))
    connection.tls = false
    connection.state = .completed
    connection.establishmentReport = .init(
      duration: 1,
      attemptStartedAfterInterval: 0,
      previousAttemptCount: 0,
      sourceEndpoint: .hostPort(host: "192.168.1.2", port: 63532),
      usedProxy: true,
      proxyEndpoint: .hostPort(host: "127.0.0.1", port: 4444),
      resolutions: [
        .init(
          source: .cache,
          duration: 0.14,
          endpointCount: 1,
          successfulEndpoint: .hostPort(host: "192.168.1.2", port: 63532),
          preferredEndpoint: .hostPort(host: "192.168.1.2", port: 63532),
          dnsProtocol: .udp
        )
      ]
    )
    connection.forwardingReport = .init(
      duration: 1,
      forwardProtocol: "HTTP",
      forwardingRule: "FINAL"
    )
    connection.dataTransferReport = .init(
      duration: 12,
      aggregatePathReport: .init(
        receivedIPPacketCount: 89,
        sentIPPacketCount: 123,
        receivedTransportByteCount: 1_231_231,
        receivedTransportDuplicateByteCount: 243,
        receivedTransportOutOfOrderByteCount: 12,
        sentTransportByteCount: 12_312_314,
        retransmittedTransportByteCount: 123,
        transportSmoothedRTT: 23,
        transportMinimumRTT: 34,
        transportRTTVariance: 12,
        receivedApplicationByteCount: 12414,
        sentApplicationByteCount: 8347
      ),
      pathReport: .init()
    )
    connection.processReport = .init(
      processIdentifier: 555,
      program: Program(
        localizedName: "t",
        bundleURL: nil,
        executableURL: nil,
        iconTIFFRepresentation: nil
      )
    )
    connection.earliestBeginDate = .distantPast

    let data = try JSONEncoder().encode(connection)
    let result = try JSONDecoder().decode(Connection.self, from: data)
    #expect(result.originalRequest == connection.originalRequest)
    #expect(result.currentRequest == connection.currentRequest)
    #expect(result.response == connection.response)
    #expect(result.tls == connection.tls)
    #expect(result.state == connection.state)
    #expect(result.establishmentReport == connection.establishmentReport)
    #expect(result.forwardingReport == connection.forwardingReport)
    #expect(result.dataTransferReport == connection.dataTransferReport)
    #expect(result.processReport == connection.processReport)
    #expect(result.earliestBeginDate == connection.earliestBeginDate)
  }

  #if swift(>=6.3) || canImport(Darwin)
    @available(SwiftStdlib 5.9, *)
    @Test func persistentModel() {
      let source = Connection.PersistentModel.self
      #expect(source == V1._Connection.self)
    }

    @available(SwiftStdlib 5.9, *)
    @Test func initializeConnectionFromPersistentModel() {
      let data = V1._Connection()
      data.taskIdentifier = 123
      data.earliestBeginDate = Date()
      data.taskDescription = "test"
      data.duration = .seconds(239842)
      data.tls = true
      data.state = .completed

      let connection = Connection(persistentModel: data)
      #expect(connection.taskIdentifier == data.taskIdentifier)
      #expect(connection.originalRequest == nil)
      #expect(connection.currentRequest == nil)
      #expect(connection.response == nil)
      #expect(connection.earliestBeginDate == data.earliestBeginDate)
      #expect(connection.duration == data.duration)
      #expect(connection.taskDescription == data.taskDescription)
      #expect(connection.tls == data.tls)
      #expect(connection.state == data.state)
      #expect(connection.establishmentReport == nil)
      #expect(connection.forwardingReport == nil)
      #expect(connection.processReport == nil)
      #expect(connection.dataTransferReport == nil)
    }
  #endif
}
