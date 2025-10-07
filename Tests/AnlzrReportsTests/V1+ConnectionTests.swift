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

import NEAddressProcessing
import Testing

@testable import AnlzrReports

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  import SwiftData
#endif

@Suite struct V1_ConnectionTests {

  @available(SwiftStdlib 5.9, *)
  @Test func propertyInitialValues() {
    let connection = V1._Connection()
    #expect(connection.taskIdentifier == 0)
    #expect(connection.originalRequest == nil)
    #expect(connection.currentRequest == nil)
    #expect(connection.response == nil)
    #expect(connection.earliestBeginDateFormatted != "")
    #expect(connection.taskDescription == "")
    #expect(connection.tls == false)
    #expect(connection.state == .establishing)
    #expect(connection.establishmentReport == nil)
    #expect(connection.forwardingReport == nil)
    #expect(connection.dataTransferReport == nil)
    #expect(connection.processReport == nil)
  }

  @available(SwiftStdlib 5.9, *)
  @Test func connectionIdentifiable() {
    #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
      let connection = V1._Connection()
      #expect(connection.id == connection.persistentModelID)
    #else
      let connection = V1._Connection()
      #expect(connection.persistentModelID == connection.taskIdentifier)
      #expect(connection.id == connection.persistentModelID)
    #endif
  }

  @available(SwiftStdlib 5.9, *)
  @Test func mergeValues() {
    let date = Date()
    let data = Connection(taskIdentifier: 55)
    data.earliestBeginDate = date
    data._duration = 1000
    data.taskDescription = "descA"
    data.tls = false
    data.state = .active
    data.forwardingReport = .init()

    let connection = V1._Connection()
    connection.taskIdentifier = 1
    connection.earliestBeginDate = date
    connection.taskDescription = "descB"
    connection.tls = true
    connection.state = .completed
    connection.forwardingReport = .init()

    connection.mergeValues(data)

    #expect(connection.taskIdentifier == 55)
    #expect(connection.earliestBeginDate == date)
    #expect(
      connection.earliestBeginDateFormatted == date.formatted(.dateTime.hour().minute().second())
    )
    #expect(connection.duration == .seconds(1000))
    #expect(connection.taskDescription == "descA")
    #expect(connection.tls == false)
    #expect(connection.state == .active)
  }
}
