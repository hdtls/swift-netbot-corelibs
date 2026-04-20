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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
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
  public class _HTTPFieldsRewrite {

    /// A boolean value determinse whether this rule is enabled or disabled.
    public var isEnabled = true

    /// An enum define HTTP directions.
    public typealias Direction = HTTPFieldsRewrite.Direction

    /// Direction of HTTP communication.
    public var direction = Direction.request

    /// Incoming request URL matching pattern.
    public var pattern = ""

    /// An enum define modification actions.
    public typealias Action = HTTPFieldsRewrite.Action

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

    /// Relationship with `_Profile`.
    public var lazyProfile: _Profile?

    /// Create a `HTTPFieldsRewrite.Model` with default values.
    public init() {
    }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._HTTPFieldsRewrite {
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
