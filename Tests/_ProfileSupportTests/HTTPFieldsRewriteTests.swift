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

import Testing

@testable import _ProfileSupport

@Suite(.tags(.httpFieldsRewrite))
struct HTTPFieldsRewriteTests {

  @Test func propertyInitialValue() async throws {
    let data = HTTPFieldsRewrite()
    #expect(data.isEnabled)
    #expect(data.direction == .request)
    #expect(data.pattern == "")
    #expect(data.action == .add)
    #expect(data.name == "")
    #expect(data.value == "")
    #expect(data.replacement == "")
  }
}

@Suite("HTTPFieldsRewrite.DirectionTests", .tags(.httpFieldsRewrite))
struct HTTPFieldsRewriteDirectionTests {

  @Test(
    arguments: zip(
      HTTPFieldsRewrite.Direction.allCases, ["request", "response"]
    )
  )
  func rawRepresentableConformance(_ type: HTTPFieldsRewrite.Direction, _ rawValue: String) {
    #expect(HTTPFieldsRewrite.Direction(rawValue: rawValue) == type)
    #expect(type.rawValue == rawValue)
    #expect(HTTPFieldsRewrite.Direction(rawValue: "unknown") == nil)
  }

  @Test func caseIterableConformance() {
    #expect(HTTPFieldsRewrite.Direction.allCases == [.request, .response])
  }
}

@Suite("HTTPFieldsRewrite.Action", .tags(.urlRewrite))
struct HTTPFieldsRewriteActionTests {

  @Test(
    arguments: zip(
      HTTPFieldsRewrite.Action.allCases, ["add", "remove", "replace"]
    )
  )
  func rawRepresentableConformance(_ type: HTTPFieldsRewrite.Action, _ rawValue: String) {
    #expect(HTTPFieldsRewrite.Action(rawValue: rawValue) == type)
    #expect(type.rawValue == rawValue)
    #expect(HTTPFieldsRewrite.Action(rawValue: "unknown") == nil)
  }

  @Test func caseIterableConformance() {
    #expect(HTTPFieldsRewrite.Action.allCases == [.add, .remove, .replace])
  }
}
