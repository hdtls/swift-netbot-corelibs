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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
/// The errors reprensent the issues that occur when resolving services over DNS.
public enum DNSError: Error {

  /// This error indicates that the DNS system or the service provider refuses the operation.
  case operationRefused

  /// This error indicates that the DNS system or the service provider does not support the operation.
  case operationUnsupported

  /// This error indicates that a network operation took too long and exceeded the time limit, so the
  /// request is considered unsuccessful.
  ///
  /// This could be caused by network issues, slow servers, or congestion.
  case timeout
}
