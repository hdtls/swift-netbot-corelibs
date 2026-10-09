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

/// `CoreVPNTaskTracker` prtocol define a service to broadcast all VPN task connections.
@available(SwiftStdlib 6.0, *)
public protocol CoreVPNTaskTracker: Sendable {

  func broadcast(_ task: Connection) async
}

@available(SwiftStdlib 6.0, *)
struct DefaultVPNTaskTracker: CoreVPNTaskTracker {
  func broadcast(_ task: Connection) async {
  }
}
