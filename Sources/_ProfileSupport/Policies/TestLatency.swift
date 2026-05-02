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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

/// An object that contains definitions of how to measure network latency.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct MeasurePolicy: Codable, Hashable, Sendable {

  // The URL used to test latency.
  public var testURL: URL?

  /// Timeout interval for latency test.
  public var timeoutInterval: Duration {
    get { .seconds(_timeoutInterval) }
    set {
      let (seconds, attoseconds) = newValue.components
      _timeoutInterval = Double(seconds) + Double(attoseconds) / 1_000_000_000_000_000_000
    }
  }

  /// Timeout interval in seconds.
  public var _timeoutInterval: Double = 5

  /// Transaction metrics expiry time interval.
  public var transactionMetricsExpiryInterval: Duration {
    get { .seconds(_transactionMetricsExpiryInterval) }
    set {
      let (seconds, attoseconds) = newValue.components
      _transactionMetricsExpiryInterval =
        Double(seconds) + Double(attoseconds) / 1_000_000_000_000_000_000
    }
  }

  /// Transaction metrics expiry time interval in seconds.
  public var _transactionMetricsExpiryInterval: Double = 300

  public init(
    testURL: URL? = nil,
    timeoutInterval: Duration = .seconds(5),
    transactionMetricsExpiryInterval: Duration = .seconds(300)
  ) {
    self.testURL = testURL
    self.timeoutInterval = timeoutInterval
    self.transactionMetricsExpiryInterval = transactionMetricsExpiryInterval
  }
}

/// An object that encapsualtes the performance metrics during the execution of a network speed test.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct TransactionMetrics: Codable, Hashable, Sendable {

  /// The maximum amount of data that can be transmitted over a network in a given amount of time.
  public var bandwidth: Int

  /// The lag or dely in data transmission over a netwrok.
  public var latency: Duration {
    get { .seconds(_latency) }
    set {
      let (seconds, attoseconds) = newValue.components
      _latency = Double(seconds) + Double(attoseconds) / 1_000_000_000_000_000_000
    }
  }
  public var _latency = Double.zero

  /// RTT, the time it takes for a packet to travel from sender to the receive and back again.
  public var roundTripTime: Duration {
    get { .seconds(_roundTripTime) }
    set {
      let (seconds, attoseconds) = newValue.components
      _roundTripTime = Double(seconds) + Double(attoseconds) / 1_000_000_000_000_000_000
    }
  }
  public var _roundTripTime = Double.zero

  /// PLR, the number of packets that fail to transfer from one destination to another.
  public var packetLoss: Int

  public var tolerance: Int = 0

  public var creationDate: Date

  public init(
    bandwidth: Int = 0,
    latency: Duration = .zero,
    roundTripTime: Duration = .zero,
    packetLoss: Int = .max,
    creationDate: Date = .now
  ) {
    self.bandwidth = bandwidth
    self.packetLoss = packetLoss
    self.creationDate = creationDate
    self.latency = latency
    self.roundTripTime = roundTripTime
  }
}
