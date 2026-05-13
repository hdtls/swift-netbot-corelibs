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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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

  var prettyPrinted: String {
    switch self {
    case .seconds(let int):
      return "\(int) s"
    case .milliseconds(let int):
      guard int >= 1_000 else {
        return "\(int) ms"
      }
      return "\(int / 1_000) s"
    case .microseconds(let int):
      guard int >= 1_000 else {
        return "\(int) µs"
      }
      guard int >= 1_000_000 else {
        return "\(int / 1_000) ms"
      }
      return "\(int / 1_000_000) s"
    case .nanoseconds(let int):
      guard int >= 1_000 else {
        return "\(int) ns"
      }
      guard int >= 1_000_000 else {
        return "\(int / 1_000) µs"
      }
      guard int >= 1_000_000_000 else {
        return "\(int / 1_000_000) ms"
      }
      return "\(int / 1_000_000_000) s"
    case .never:
      return "n/a"
    #if canImport(Darwin)
      @unknown default:
        return "n/a"
    #endif
    }
  }
}
