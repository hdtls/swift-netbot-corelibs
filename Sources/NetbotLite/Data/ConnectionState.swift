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
extension Connection {

  /// A enum represents the progression of a `Connection` through stages.
  public enum State: String, CaseIterable, Codable, Hashable, RawRepresentable, Sendable {

    /// Establishing connections are actively establishing the connection
    case establishing

    /// Active connections can send and receive data
    case active

    /// Completed connections has finished send or receive data.
    case completed

    /// Failed connections are disconnected and can no longer send or receive data
    case failed

    /// Cancelled connections have been invalidated by the client and will send no more events
    case cancelled
  }
}
