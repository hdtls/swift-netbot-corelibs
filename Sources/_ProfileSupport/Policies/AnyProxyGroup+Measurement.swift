//
// See LICENSE.txt for license information
//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
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
