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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension AnyProxyGroup {

  /// An object representing network measurements.
  public struct Measurement: Codable, Hashable, Sendable {

    /// Network measurement URL.
    public var url: URL?

    /// Expiry interval for current measurement.
    public var transactionMetricsExpiryInterval = 600.0

    /// Timeout for measurement in secodes.
    public var timeout = 5.0

    /// Tolerance for latency in millisecond.
    public var tolerance = 100

    /// Transaction metrics for this measrement.
    public var transactionMetrics = TransactionMetrics()

    public init(
      url: URL? = nil, transactionMetricsExpiryInterval: Double = 600.0, timeout: Double = 5.0,
      tolerance: Int = 100, transactionMetrics: TransactionMetrics = TransactionMetrics()
    ) {
      self.url = url
      self.transactionMetricsExpiryInterval = transactionMetricsExpiryInterval
      self.timeout = timeout
      self.tolerance = tolerance
      self.transactionMetrics = transactionMetrics
    }
  }
}
