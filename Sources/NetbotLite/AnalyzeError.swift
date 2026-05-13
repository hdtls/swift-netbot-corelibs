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

/// An error that can occur on AnalyzeBot operations.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public enum AnalyzeError: Error {

  /// Input stream endpoint is invalid and can not be used.
  case inputStreamEndpointInvalid

  /// Output stream endpoint is invalid and can not be used.
  case outputStreamEndpointInvalid

  /// Connection was refused. For example connection reject by user specific rules.
  case connectionRefused

  /// Unsupported operation triggered on `AnalyzeBot`.
  case operationUnsupported
}
