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

@available(SwiftStdlib 6.0, *)
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

@available(SwiftStdlib 6.0, *)
extension V1._StubbedHTTPResponse {

  /// Merge new values from DTO.
  /// - Parameter data: New `StubbedHTTPResponse` to merge.
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
