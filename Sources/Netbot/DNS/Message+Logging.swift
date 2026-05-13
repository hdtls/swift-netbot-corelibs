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

import Logging

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Message {

  public enum FormatStyle {
    case standard
    case detailed
  }

  public func formatted(_ style: FormatStyle = .standard) -> String {
    var msg = "Standard query"
    if headerFields.flags.isResponse {
      msg += " response"
    }
    msg += " \(headerFields.transactionID)"
    msg += questions.map { " \($0.queryType) \($0.domainName)" }.joined()

    guard style == .detailed else {
      return msg
    }

    msg += answerRRs.map { " \($0.dataType) \($0.domainName)" }.joined()
    msg += authorityRRs.map { " \($0.dataType) \($0.domainName)" }.joined()
    msg += additionalRRs.map { " \($0.dataType) \($0.domainName)" }.joined()
    return msg
  }
}
