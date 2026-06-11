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
struct V1_URLRewriteTests {

  @available(SwiftStdlib 6.0, *)
  @Test func propertyInitialValue() async throws {
    let data = V1._URLRewrite()
    #expect(data.isEnabled)
    #expect(data.type == .found)
    #expect(data.pattern == "")
    #expect(data.destination == "")
  }

  @available(SwiftStdlib 6.0, *)
  @Test("URLRewrite.init(persistentModel:)") func initWithPersistentModel() {
    let persistentModel = V1._URLRewrite()
    let urlRewrite = URLRewrite(persistentModel: persistentModel)
    #expect(urlRewrite.isEnabled == persistentModel.isEnabled)
    #expect(urlRewrite.type == persistentModel.type)
    #expect(urlRewrite.pattern == persistentModel.pattern)
    #expect(urlRewrite.destination == persistentModel.destination)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func mergeValues() {
    let urlRewrite = URLRewrite()
    let persistentModel = V1._URLRewrite()
    persistentModel.mergeValues(urlRewrite)

    #expect(urlRewrite.isEnabled == persistentModel.isEnabled)
    #expect(urlRewrite.type == persistentModel.type)
    #expect(urlRewrite.pattern == persistentModel.pattern)
    #expect(urlRewrite.destination == persistentModel.destination)
  }
}

@Suite(.tags(.profile, .httprewrites, .swiftdata))
struct V1_URLRewrite_RewriteTypeTests {

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      V1._URLRewrite.RewriteType.allCases,
      ["http-fields", "found", "temporary-redirect", "reject"]
    )
  )
  func rawRepresentableConformance(_ type: URLRewrite.RewriteType, _ rawValue: String) {
    #expect(V1._URLRewrite.RewriteType(rawValue: rawValue) == type)
    #expect(type.rawValue == rawValue)
    #expect(V1._URLRewrite.RewriteType(rawValue: "unknown") == nil)
  }

  @available(SwiftStdlib 6.0, *)
  @Test func caseIterableConformance() {
    #expect(
      V1._URLRewrite.RewriteType.allCases == [.httpFields, .found, .temporaryRedirect, .reject])
  }

  @available(SwiftStdlib 6.0, *)
  @Test(
    arguments: zip(
      V1._URLRewrite.RewriteType.allCases, ["HTTP Fields", "HTTP 302", "HTTP 307", "Reject"]
    )
  )
  func localizedName(_ type: V1._URLRewrite.RewriteType, _ localizedName: String) {
    #expect(type.localizedName == localizedName)
  }
}
