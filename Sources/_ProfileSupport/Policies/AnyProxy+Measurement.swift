//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension AnyProxy {
  /// An object representing network measurements.
  public struct Measurement: Codable, Hashable, Sendable {

    /// Netwowrk measurement URL.
    public var url: URL?

    /// Metrics for measurement.
    public var transactionMetrics = TransactionMetrics()

    /// Initialize an instance of `Measurement` with specified `url` and `transactionMetrics`.`
    public init(url: URL? = nil, transactionMetrics: TransactionMetrics = TransactionMetrics()) {
      self.url = url
      self.transactionMetrics = transactionMetrics
    }
  }
}
