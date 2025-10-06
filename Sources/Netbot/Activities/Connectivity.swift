//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Alamofire
  import Foundation

  @available(SwiftStdlib 5.9, *)
  public struct Connectivity: Sendable {

    public init() {}

    /// Measure Internet latency by fetching a tiny known endpoint (defaults to Apple's connectivity check) with a HEAD request.
    ///
    /// - Parameters:
    ///   - connectivityCheckURL: The URL used to measure connectivity.
    ///   - timeoutInterval: The timeout time interval for measure request.
    /// - Returns: A tuple of duration of dns request/response circle and duration of TTFB.
    ///
    #if swift(>=6.2)
      @concurrent public func measureInternetLatency(
        connectivityCheckURL: URL? = nil, timeoutInterval: TimeInterval? = nil
      ) async throws -> (Duration, Duration) {
        try await _measureInternetLatency(
          connectivityCheckURL: connectivityCheckURL, timeoutInterval: timeoutInterval)
      }
    #else
      nonisolated public func measureInternetLatency(
        connectivityCheckURL: URL? = nil, timeoutInterval: TimeInterval? = nil
      ) async throws -> (Duration, Duration) {
        try await _measureInternetLatency(
          connectivityCheckURL: connectivityCheckURL, timeoutInterval: timeoutInterval)
      }
    #endif

    private func _measureInternetLatency(
      connectivityCheckURL: URL? = nil, timeoutInterval: TimeInterval? = nil
    ) async throws -> (
      Duration,
      Duration
    ) {
      let urlConvertible =
        connectivityCheckURL?.absoluteString ?? "https://captive.apple.com/hotspot-detect.html"

      let configuration = URLSessionConfiguration.default
      configuration.proxyConfigurations = []
      configuration.connectionProxyDictionary = [:]
      configuration.timeoutIntervalForRequest = timeoutInterval ?? 5.0

      let session = Session(configuration: configuration)
      let metrics = await session.request(urlConvertible, method: .head).serializingData().response
        .metrics

      var result = (Duration.seconds(0), Duration.seconds(0))

      guard let transactionMetrics = metrics?.transactionMetrics.first else {
        return result
      }

      if let domainLookupStartDate = transactionMetrics.domainLookupStartDate,
        let domainLookupEndDate = transactionMetrics.domainLookupEndDate
      {
        result.0 = .seconds(domainLookupStartDate.distance(to: domainLookupEndDate))
      }

      if let requestStartDate = transactionMetrics.requestStartDate,
        let responseStartDate = transactionMetrics.responseStartDate
      {
        result.1 = .seconds(requestStartDate.distance(to: responseStartDate))
      }

      return result
    }
  }
#endif
