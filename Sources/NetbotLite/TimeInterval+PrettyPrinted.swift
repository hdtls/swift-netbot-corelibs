//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2022 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

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

@available(SwiftStdlib 5.3, *)
extension DispatchTimeInterval {

  var timeInterval: Double {
    switch self {
    case .seconds(let seconds):
      return Double(seconds)
    case .milliseconds(let milliseconds):
      return Double(milliseconds / 1_000)
    case .microseconds(let microseconds):
      return Double(microseconds / 1_000_000)
    case .nanoseconds(let nanoseconds):
      return Double(nanoseconds / 1_000_000_000)
    case .never:
      return .infinity
    #if canImport(Darwin)
      @unknown default:
        assertionFailure()
        return 0
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

@available(SwiftStdlib 5.3, *)
extension Double {

  var timeInterval: DispatchTimeInterval {
    .nanoseconds(Int(self * 1_000_000_000))
  }
}
