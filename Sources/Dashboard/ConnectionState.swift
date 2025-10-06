//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import AnlzrReports

@available(SwiftStdlib 5.3, *)
extension Connection.State {

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
