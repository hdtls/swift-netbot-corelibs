//
// See LICENSE.txt for license information
//

#if canImport(Darwin)
  import Foundation

  @available(SwiftStdlib 5.9, *)
  public struct Connectivity: Sendable {

    private class SessionDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {

      var urlSessionTaskDidFinishCollectingMetrics:
        (
          (URLSession, URLSessionTask, URLSessionTaskMetrics) -> Void
        )?

      func urlSession(
        _ session: URLSession, task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
      ) {
        urlSessionTaskDidFinishCollectingMetrics?(session, task, metrics)
      }

      func urlSession(
        _ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?
      ) {

      }
    }

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
      try await withCheckedThrowingContinuation { continuation in
        let connectivityCheckURL =
          connectivityCheckURL ?? URL(
            string: "https://captive.apple.com/hotspot-detect.html"
          )!
        let timeoutInterval = timeoutInterval ?? 5.0
        var urlRequest = URLRequest(url: connectivityCheckURL)
        urlRequest.httpMethod = "HEAD"
        urlRequest.timeoutInterval = timeoutInterval

        let configuration = URLSessionConfiguration.default
        configuration.proxyConfigurations = []
        configuration.connectionProxyDictionary = [:]

        let sessionDelegate = SessionDelegate()
        sessionDelegate.urlSessionTaskDidFinishCollectingMetrics = { _, _, metrics in
          guard let transactionMetrics = metrics.transactionMetrics.first else {
            return
          }

          var result = (Duration.seconds(0), Duration.seconds(0))

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

          continuation.resume(returning: result)
        }

        let session = URLSession(
          configuration: configuration,
          delegate: sessionDelegate,
          delegateQueue: OperationQueue()
        )
        session.dataTask(with: urlRequest) { _, _, error in
          if let error {
            continuation.resume(throwing: error)
          }
        }
        .resume()
      }
    }
  }
#endif
