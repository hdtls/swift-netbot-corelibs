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

@available(SwiftStdlib 5.3, *)
extension AnyProxy {

  /// `Source`` indicates if the proxy was builtin, user defined or resolved from external resource.
  public enum Source: String, CaseIterable, Codable, Hashable, Sendable {

    /// Built-in.
    case builtin

    /// User defined.
    case userDefined

    /// Resolved from external resource..
    case externalResource
  }
}
