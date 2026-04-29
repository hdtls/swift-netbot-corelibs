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

import NEAddressProcessing
import NetbotLiteData

/// Protocol for process report generator
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public protocol ProcessReporting: Sendable {

  /// Request process info with socket address.
  ///
  /// - Parameter connection: Connection the requested process runs on.
  /// - Returns: Generated process report.
  func processInfo(connection: Connection) async throws -> ProcessReport
}

/// A default `ProcessReporting` object.
///
/// Return an empty report entity for process info report request by default.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
struct DefaultProcessReporting: ProcessReporting {

  func processInfo(connection: Connection) async throws -> ProcessReport {
    return .init()
  }
}
