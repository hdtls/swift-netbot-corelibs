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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Connection.State {

  var isFinished: Bool {
    switch self {
    case .establishing, .active:
      return false
    case .completed, .failed, .cancelled:
      return true
    }
  }

  public var localizedName: String {
    switch self {
    case .establishing:
      return "Establishing"
    case .active:
      return "Active"
    case .completed:
      return "Completed"
    case .failed:
      return "Failed"
    case .cancelled:
      return "Cancelled"
    }
  }
}
