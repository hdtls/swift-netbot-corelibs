//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import Logging
import NetbotLiteData

@available(SwiftStdlib 5.3, *)
extension Connection {

  internal var metadata: Logger.Metadata {
    ["Request": "#\(taskIdentifier) \(originalRequest?.address.map { "\($0)" } ?? "unknown host")"]
  }

  func satisfy(predicate: (Connection) throws -> Bool) rethrows -> Bool {
    try predicate(self)
  }
}

@available(SwiftStdlib 5.3, *)
extension Connection.State {
  var isFinished: Bool {
    switch self {
    case .establishing, .active:
      return false
    case .completed, .failed, .cancelled:
      return true
    }
  }
}
