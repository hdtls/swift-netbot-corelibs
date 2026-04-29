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

/// An object that encapsualtes the performance metrics during the execution of a network speed test.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct TransactionMetrics: Codable, Equatable, Hashable, Sendable {

  /// The maximum amount of data that can be transmitted over a network in a given amount of time.
  public var bandwidth: Int

  /// The lag or dely in data transmission over a netwrok.
  public var latency: Int

  /// RTT, the time it takes for a packet to travel from sender to the receive and back again.
  public var roundTripTime: Int

  /// PLR, the number of packets that fail to transfer from one destination to another.
  public var packetLoss: Int

  public var creationDate: Date

  public init() {
    self.bandwidth = 0
    self.latency = .max
    self.roundTripTime = .max
    self.packetLoss = 100
    self.creationDate = .now
  }
}
