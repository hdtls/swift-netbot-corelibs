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

#if canImport(SwiftData)
  import SwiftData
  import Testing

  @testable import _ProfileSupport

  @Suite("v1.HTTPFieldsRewriteTests", .tags(.httpFieldsRewrite))
  struct V1_HTTPFieldsRewriteTests {

    var modelContainer: Any = 0

    init() throws {
      if #available(SwiftStdlib 5.9, *) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema: Schema = Schema(versionedSchema: _VersionedSchema.self)
        modelContainer = try ModelContainer(for: schema, configurations: configuration)
      }
    }

    @available(SwiftStdlib 5.9, *)
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

  @Suite("v1.HTTPFieldsRewrite.DirectionTests", .tags(.httpFieldsRewrite))
  struct V1_HTTPFieldsRewriteHDirectionTests {

    @available(SwiftStdlib 5.9, *)
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

    @available(SwiftStdlib 5.9, *)
    @Test func caseIterableConformance() {
      #expect(V1._HTTPFieldsRewrite.Direction.allCases == [.request, .response])
    }
  }

  @Suite("v1.HTTPFieldsRewrite.Action", .tags(.urlRewrite))
  struct V1_HTTPFieldsRewriteActionTests {

    @available(SwiftStdlib 5.9, *)
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

    @available(SwiftStdlib 5.9, *)
    @Test func caseIterableConformance() {
      #expect(V1._HTTPFieldsRewrite.Action.allCases == [.add, .remove, .replace])
    }
  }
#endif
