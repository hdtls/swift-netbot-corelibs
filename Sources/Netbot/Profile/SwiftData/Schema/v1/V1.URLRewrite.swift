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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData)
  import SwiftData
#else
  import NetbotSQL
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  @Model public class URLRewrite {

    /// A boolean value determinse whether this rule is enabled or disabled.
    public var isEnabled = true

    /// A redirection type representation object, define type of URLRewrite.
    public typealias RewriteType = NetbotProfile.URLRewrite.RewriteType

    /// Response status for this redirection.
    public var type = RewriteType.found

    /// Incoming request URL matching pattern.
    public var pattern = ""

    /// URL redirect destination.
    public var destination = ""

    /// The time the resource was created.
    public var creationDate = Date.now

    /// Relationship with `Profile`.
    public var lazyProfile: Profile?

    public init() {
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.URLRewrite {

  /// Merge new values from DTO.
  /// - Parameter data: New `URLRewrite` to merge.
  public func mergeValues(_ data: URLRewrite) {
    isEnabled = data.isEnabled
    type = data.type
    pattern = data.pattern
    destination = data.destination
    creationDate = data.creationDate
  }
}
