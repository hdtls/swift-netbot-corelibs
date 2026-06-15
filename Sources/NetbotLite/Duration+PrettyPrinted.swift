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

import Dispatch

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

// remove when available to all platforms
#if os(Linux) || os(Windows) || os(Android) || os(OpenBSD)
  extension DispatchTime {
    public func distance(to other: DispatchTime) -> DispatchTimeInterval {
      let final = other.uptimeNanoseconds
      let point = self.uptimeNanoseconds
      let duration: Int64 = Int64(
        bitPattern: final.subtractingReportingOverflow(point).partialValue
      )
      return .nanoseconds(duration >= Int.max ? Int.max : Int(duration))
    }
  }
#endif

@available(SwiftStdlib 6.0, *)
extension DispatchTimeInterval {

  var duration: Duration {
    switch self {
    case .seconds(let seconds):
      return .seconds(seconds)
    case .milliseconds(let milliseconds):
      return .milliseconds(milliseconds)
    case .microseconds(let microseconds):
      return .microseconds(microseconds)
    case .nanoseconds(let nanoseconds):
      return .nanoseconds(nanoseconds)
    case .never:
      // As we know, the process is unlikely to run `Int.max` seconds,
      // so we use the value when the duration is `Int.max` seconds to
      // represent `never`.
      return .seconds(Int.max)
    #if canImport(Darwin)
      @unknown default:
        assertionFailure()
        return .zero
    #endif
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension FormatStyle where Self == Duration.UnitsFormatStyle {

  static func prettyPrinted() -> Self {
    .init(allowedUnits: [.seconds, .milliseconds, .microseconds, .nanoseconds], width: .narrow)
  }
}
