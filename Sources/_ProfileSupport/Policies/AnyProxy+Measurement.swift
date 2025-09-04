//
// See LICENSE.txt for license information
//

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
