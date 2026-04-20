// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import Testing

@testable import NetbotLiteData

@Suite struct V1_ProcessReportTests {

  @available(SwiftStdlib 5.9, *)
  @Test func propertyInitialValues() async throws {
    let report = V1._ProcessReport()
    #expect(report.processIdentifier == nil)
  }

  @available(SwiftStdlib 5.9, *)
  func mergeValues() throws {
    let model = V1._ProcessReport()
    model.processIdentifier = 1
    let report = ProcessReport(processIdentifier: 99999)
    model.mergeValues(report)
    #expect(model.processIdentifier == 99999)
  }
}
