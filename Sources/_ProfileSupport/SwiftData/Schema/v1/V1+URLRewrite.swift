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
  public class _URLRewrite {

    /// A boolean value determinse whether this rule is enabled or disabled.
    public var isEnabled = true

    /// A redirection type representation object, define type of URLRewrite.
    public typealias RewriteType = URLRewrite.RewriteType

    /// Response status for this redirection.
    public var type = RewriteType.found

    /// Incoming request URL matching pattern.
    public var pattern = ""

    /// URL redirect destination.
    public var destination = ""

    /// The time the resource was created.
    public var creationDate = Date.now

    /// Relationship with `_Profile`.
    public var lazyProfile: _Profile?

    public init() {
    }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._URLRewrite {

  public func mergeValues(_ data: URLRewrite) {
    isEnabled = data.isEnabled
    type = data.type
    pattern = data.pattern
    destination = data.destination
    creationDate = data.creationDate
  }
}
