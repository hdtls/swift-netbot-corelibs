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

@available(SwiftStdlib 6.0, *)
extension AnyProxy {

  /// `Source` indicates if the proxy was builtin, user defined or resolved from external resource.
  public enum Source: String, CaseIterable, Codable, Hashable, Sendable {

    /// Built-in.
    case builtin

    /// User defined.
    case userDefined

    /// Resolved from external resource..
    case externalResource
  }
}
