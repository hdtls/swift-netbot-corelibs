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

  @Model public class HTTPFieldsRewrite {

    /// A boolean value determinse whether this rule is enabled or disabled.
    public var isEnabled = true

    /// An enum define HTTP directions.
    public typealias Direction = NetbotProfile.HTTPFieldsRewrite.Direction

    /// Direction of HTTP communication.
    public var direction = Direction.request

    /// Incoming request URL matching pattern.
    public var pattern = ""

    /// An enum define modification actions.
    public typealias Action = NetbotProfile.HTTPFieldsRewrite.Action

    /// Action for modification.
    public var action = Action.add

    /// HTTP header field name.
    public var name = ""

    /// A regex describing the field value to replace.
    public var replacement = ""

    /// HTTP header field value.
    public var value = ""

    /// The time the resource was created.
    public var creationDate = Date.now

    /// Relationship with `Profile`.
    public var lazyProfile: Profile?

    /// Create a `HTTPFieldsRewrite.Model` with default values.
    public init() {
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.HTTPFieldsRewrite {

  /// Merge new values from DTO.
  /// - Parameter data: New `HTTPFieldsRewrite` to merge.
  public func mergeValues(_ data: HTTPFieldsRewrite) {
    isEnabled = data.isEnabled
    direction = data.direction
    pattern = data.pattern
    action = data.action
    name = data.name
    replacement = data.replacement
    value = data.value
    creationDate = data.creationDate
  }
}
