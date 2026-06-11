// ===----------------------------------------------------------------------=== //
//
// This source file is part of the Netbot open source project
//
// Copyright © 2025-2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See https://www.apache.org/licenses/LICENSE-2.0 for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------=== //

import NetbotLite
import Preference

#if canImport(Darwin)
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
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

@available(SwiftStdlib 6.0, *)
extension OutboundMode: PreferenceRepresentable {}
