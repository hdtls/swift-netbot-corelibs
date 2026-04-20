// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

/// An error that can occur on AnalyzeBot operations.
@available(SwiftStdlib 5.3, *)
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
