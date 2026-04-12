//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 5.3, *)
extension Connection {

  /// States a connection may be in
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
