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

import Preference

/// An OptionSet for proxy mode.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct ProxyMode: OptionSet, RawRepresentable, Hashable, Sendable {

  public var rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Default proxy mode, enable both HTTP/HTTPS proxy.
  public static let webProxy = ProxyMode(rawValue: 1 << 0)

  /// By set proxy mode to `systemProxy`, we are modify system network proxies.
  public static let systemProxy = ProxyMode(rawValue: 1 << 1)

  /// Enable IP layer proxy.
  public static let enhanced = ProxyMode(rawValue: 1 << 2)
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ProxyMode: PreferenceRepresentable {}
