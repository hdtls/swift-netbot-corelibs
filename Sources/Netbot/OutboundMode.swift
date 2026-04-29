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

import NetbotLite
import Preference

#if canImport(Darwin)
  import Foundation
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension OutboundMode {
  var localizedName: String {
    #if canImport(Darwin)
      switch self {
      case .direct: return String(localized: "Direct Outbound", comment: "")
      case .globalProxy: return String(localized: "Global Proxy", comment: "")
      case .ruleBased: return String(localized: "Rule-based Proxy", comment: "")
      }
    #else
      switch self {
      case .direct:
        return "Direct Outbound"
      case .globalProxy:
        return "Global Proxy"
      case .ruleBased:
        return "Rule-based Proxy"
      }
    #endif
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension OutboundMode: PreferenceRepresentable {}
