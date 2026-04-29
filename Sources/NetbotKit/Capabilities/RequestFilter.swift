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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public enum RequestFilterStrategy: Int, CaseIterable, Hashable, Sendable {
  case noFilter
  case withKeywords
  case withoutKeywords
  case matchPatterns
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension RequestFilterStrategy {

  public var abstract: String {
    switch self {
    case .noFilter:
      return "No Filter"
    case .withKeywords:
      return "Record Requests with Keywords Only"
    case .withoutKeywords:
      return "Record Requests without Keywords Only"
    case .matchPatterns:
      return "Record Requests Match Patterns"
    }
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension RequestFilterStrategy: PreferenceRepresentable {}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct RequestFilter: Hashable, Sendable {

  public var strategy: RequestFilterStrategy

  public var values: [String]

  public init(strategy: RequestFilterStrategy = .noFilter, values: [String] = []) {
    self.strategy = strategy
    self.values = values
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension RequestFilter: PreferenceRepresentable {

  public init?(preferenceValue: Any) {
    guard let prefs = preferenceValue as? [String: Any] else {
      return nil
    }

    guard let rawValue = prefs["strategy"] as? Int,
      let strategy = RequestFilterStrategy(rawValue: rawValue)
    else {
      return nil
    }
    self.strategy = strategy
    self.values = prefs["values"] as? [String] ?? []
  }

  public var preferenceValue: Any? {
    ["strategy": strategy.preferenceValue, "values": values]
  }
}
