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

@available(SwiftStdlib 5.3, *)
extension OutboundMode {
  var localizedName: String {
    #if canImport(Darwin)
      if #available(SwiftStdlib 5.5, *) {
        switch self {
        case .direct: return String(localized: "Direct Outbound", comment: "")
        case .globalProxy: return String(localized: "Global Proxy", comment: "")
        case .ruleBased: return String(localized: "Rule-based Proxy", comment: "")
        }
      } else {
        switch self {
        case .direct: return NSLocalizedString("Direct Outbound", comment: "")
        case .globalProxy: return NSLocalizedString("Global Proxy", comment: "")
        case .ruleBased: return NSLocalizedString("Rule-based Proxy", comment: "")
        }
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

@available(SwiftStdlib 5.3, *)
extension OutboundMode: PreferenceRepresentable {}
