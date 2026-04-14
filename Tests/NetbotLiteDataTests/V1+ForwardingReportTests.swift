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

@testable import NetbotLiteData

@Suite struct V1_ForwardingReportTests {

  @available(SwiftStdlib 5.9, *)
  @Test func persistentModelTypealias() {
    #expect(ForwardingReport.Model.self == V1._ForwardingReport.self)
  }

  @available(SwiftStdlib 5.9, *)
  @Test func mergeValues() {
    let model = V1._ForwardingReport()

    let data = ForwardingReport(
      duration: 13.5,
      forwardProtocol: "REJECT",
      forwardingRule: "FINAL"
    )

    model.mergeValues(data)

    #expect(model._duration == 13.5)
    #expect(model.forwardProtocol == "REJECT")
    #expect(model.forwardingRule == "FINAL")
  }
}
