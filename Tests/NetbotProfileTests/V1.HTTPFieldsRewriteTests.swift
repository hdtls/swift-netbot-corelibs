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

import Testing

@testable import NetbotProfile

@Suite(.tags(.profile, .httprewrites, .swiftdata))
struct V1_HTTPFieldsRewriteTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() async throws {
    let data = V1._HTTPFieldsRewrite()
    #expect(data.isEnabled)
    #expect(data.direction == .request)
    #expect(data.pattern == "")
    #expect(data.action == .add)
    #expect(data.name == "")
    #expect(data.value == "")
    #expect(data.replacement == "")
  }
}

@Suite(.tags(.profile, .httprewrites, .swiftdata))
struct V1_HTTPFieldsRewrite_DirectionTests {

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      V1._HTTPFieldsRewrite.Direction.allCases, ["request", "response"]
    )
  )
  func rawRepresentableConformance(_ type: V1._HTTPFieldsRewrite.Direction, _ rawValue: String) {
    #expect(V1._HTTPFieldsRewrite.Direction(rawValue: rawValue) == type)
    #expect(type.rawValue == rawValue)
    #expect(V1._HTTPFieldsRewrite.Direction(rawValue: "unknown") == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func caseIterableConformance() {
    #expect(V1._HTTPFieldsRewrite.Direction.allCases == [.request, .response])
  }
}

@Suite(.tags(.profile, .httprewrites, .swiftdata))
struct V1_HTTPFieldsRewrite_ActionTests {

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      V1._HTTPFieldsRewrite.Action.allCases, ["add", "remove", "replace"]
    )
  )
  func rawRepresentableConformance(_ type: V1._HTTPFieldsRewrite.Action, _ rawValue: String) {
    #expect(V1._HTTPFieldsRewrite.Action(rawValue: rawValue) == type)
    #expect(type.rawValue == rawValue)
    #expect(V1._HTTPFieldsRewrite.Action(rawValue: "unknown") == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func caseIterableConformance() {
    #expect(V1._HTTPFieldsRewrite.Action.allCases == [.add, .remove, .replace])
  }
}
