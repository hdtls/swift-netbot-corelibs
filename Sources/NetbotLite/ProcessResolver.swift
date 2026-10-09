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

import NEAddressProcessing
import NetbotLiteData

/// Protocol for process resolver
@available(SwiftStdlib 6.0, *)
public protocol ProcessResolver: Sendable {

  /// Resolve process info with connection.
  func processInfo(connection: Connection) async throws -> ProcessReport
}

@available(SwiftStdlib 6.0, *)
struct DefaultProcessResolver: ProcessResolver {

  func processInfo(connection: Connection) async throws -> ProcessReport {
    .init()
  }
}
