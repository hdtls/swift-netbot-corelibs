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

import NetbotLiteData

/// `ConnectionPublisher` prtocol define a service to transfer connections.
@available(SwiftStdlib 6.0, *)
public protocol ConnectionPublisher: Sendable {

  func send(_ connection: Connection) async
}

@available(SwiftStdlib 6.0, *)
struct DefaultConnectionPublisher: ConnectionPublisher {
  func send(_ connection: Connection) async {
  }
}
