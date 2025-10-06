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

@Suite(.tags(.urlRewrite))
struct URLRewriteTests {

  @Test func propertyInitialValue() async throws {
    let data = URLRewrite()
    #expect(data.isEnabled)
    #expect(data.type == .found)
    #expect(data.pattern == "")
    #expect(data.destination == "")
  }
}

@Suite("URLRewrite.RewriteTypeTests", .tags(.urlRewrite))
struct URLRewriteRewriteTypeTests {

  @Test(
    arguments: zip(
      URLRewrite.RewriteType.allCases, ["http-fields", "found", "temporary-redirect", "reject"]
    )
  )
  func rawRepresentableConformance(_ type: URLRewrite.RewriteType, _ rawValue: String) {
    #expect(URLRewrite.RewriteType(rawValue: rawValue) == type)
    #expect(type.rawValue == rawValue)
    #expect(URLRewrite.RewriteType(rawValue: "unknown") == nil)
  }

  @Test func caseIterableConformance() {
    #expect(URLRewrite.RewriteType.allCases == [.httpFields, .found, .temporaryRedirect, .reject])
  }

  @Test(
    arguments: zip(
      URLRewrite.RewriteType.allCases, ["HTTP Fields", "HTTP 302", "HTTP 307", "Reject"]
    )
  )
  func localizedName(_ type: URLRewrite.RewriteType, _ localizedName: String) {
    #expect(type.localizedName == localizedName)
  }
}
