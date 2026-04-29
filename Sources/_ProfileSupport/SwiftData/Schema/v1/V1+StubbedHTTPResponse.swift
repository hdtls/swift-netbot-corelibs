// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

import HTTPTypes

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(SwiftData)
  import SwiftData
#endif

#if swift(>=6.3)
  import Observation
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1 {

  #if canImport(SwiftData)
    @Model
  #else
    #if swift(>=6.3)
      @Observable
    #endif
  #endif
  public class _StubbedHTTPResponse {

    /// A boolean value determinse whether this rule is enabled or disabled.
    public var isEnabled = true

    /// Incoming request URL matching pattern.
    public var pattern = ""

    /// Response body content URL.
    public var bodyContentsURL: URL?

    /// Response status code.
    public var statusCode = 200

    /// Response status reason phrase.
    public var reasonPhrase = ""

    /// Additional HTTP fields for stubbed response.
    public var additionalHTTPFields = HTTPFields()

    /// The time the resource was created.
    public var creationDate = Date.now

    /// Relationship with `_Profile`.
    public var lazyProfile: _Profile?

    public init() {
    }
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._StubbedHTTPResponse {
  public func mergeValues(_ data: StubbedHTTPResponse) {
    isEnabled = data.isEnabled
    pattern = data.pattern
    bodyContentsURL = data.bodyContentsURL
    statusCode = data.status.code
    reasonPhrase = data.status.reasonPhrase
    additionalHTTPFields = data.additionalHTTPFields
    creationDate = data.creationDate
  }
}
