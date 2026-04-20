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

import Logging
import _DNSSupport

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Message {

  enum FormatStyle {
    case standard
    case detailed
  }

  func formatted(_ style: FormatStyle = .standard) -> String {
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
