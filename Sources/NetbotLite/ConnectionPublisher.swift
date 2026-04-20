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

import NetbotLiteData

/// `ConnectionPublisher` prtocol define a service to transfer connections.
@available(SwiftStdlib 5.3, *)
public protocol ConnectionPublisher: Sendable {

  func send(_ connection: Connection) async
}

@available(SwiftStdlib 5.3, *)
struct DefaultConnectionPublisher: ConnectionPublisher {
  func send(_ connection: Connection) async {
  }
}
