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

#if canImport(Darwin)
  import Alamofire
  import Dispatch
  import Foundation
  import Logging
  import Synchronization

  #if canImport(Network)
    import Network
  #endif

  /// An object contains operations of latency tests.
  @available(SwiftStdlib 6.0, *)
  final public class Diagnostics: Sendable {

    private let logger = Logger(label: "com.tenbits.diagnostics")

    /// Create a instance of `Diagnostics`.
    nonisolated public init() {
    }

    /// Measure router latency by connect to a specific router address.
    ///
    /// - Parameter address: Router address.
    /// - Returns: Duration of router latency.
    ///
    @concurrent public func testRouterLatency(address: NWEndpoint.Host) async -> Duration {
      #if canImport(Network)
        await withCheckedContinuation { continuation in
          let connection = NWConnection(to: .hostPort(host: address, port: 80), using: .tcp)

          let onceToken = Mutex(false)
          @Sendable func resume(returning duration: Duration) {
            let resume = onceToken.withLock {
              if $0 {
                return false
              } else {
                $0 = true
                return true
              }
            }
            guard resume else { return }
            continuation.resume(returning: duration)
          }

          let timeoutTask = Task {
            try await Task.sleep(for: .seconds(5))
            try Task.checkCancellation()

            guard case .ready = connection.state else {
              connection.forceCancel()
              resume(returning: .max)
              return
            }
          }

          let startTime: Date = .now

          connection.stateUpdateHandler = {
            switch $0 {
            case .ready:
              resume(returning: .seconds(startTime.distance(to: .now)))
              timeoutTask.cancel()
              connection.forceCancel()
            case .failed, .cancelled:
              resume(returning: .max)
              timeoutTask.cancel()
            default:
              break
            }
          }
          connection.start(queue: .global())
        }
      #else
        .max
      #endif
    }

    /// Measure DNS latency by resolving a tiny known host with a DNS query.
    ///
    /// - Parameters:
    ///   - url: The URL contains host to resolve, if nil the Apple's connectivity check host will be used.
    ///   - timeoutInterval: The timeout time interval for measure request, if nil 5 seconds wil lbe used.
    /// - Returns: Duration of dns request/response circle.
    ///
    @concurrent public func testDNSLatency(url: URL? = nil, timeoutInterval: Double? = nil) async
      -> Duration
    {
      let urlConvertible = url?.absoluteString ?? "https://captive.apple.com/hotspot-detect.html"

      let configuration = URLSessionConfiguration.default
      configuration.connectionProxyDictionary = [:]
      configuration.proxyConfigurations = []
      configuration.timeoutIntervalForRequest = timeoutInterval ?? 5.0

      let session = Alamofire.Session(configuration: configuration)
      let metrics = await session.request(urlConvertible, method: .head).serializingData().response
        .metrics

      guard let transactionMetrics = metrics?.transactionMetrics.first,
        let domainLookupStartDate = transactionMetrics.domainLookupStartDate,
        let domainLookupEndDate = transactionMetrics.domainLookupEndDate
      else {
        return .zero
      }

      return .seconds(domainLookupStartDate.distance(to: domainLookupEndDate))
    }

    /// Measure Internet latency by fetching a tiny known endpoint (defaults to Apple's connectivity check) with a HEAD request.
    ///
    /// - Parameters:
    ///   - url: The URL used to measure connectivity.
    ///   - timeoutInterval: The timeout time interval for measure request.
    /// - Returns: Duration of TTFB.
    ///
    @concurrent public func testInternetLatency(url: URL? = nil, timeoutInterval: Double? = nil)
      async -> Duration
    {
      let urlConvertible = url?.absoluteString ?? "https://captive.apple.com/hotspot-detect.html"

      let configuration = URLSessionConfiguration.default
      configuration.connectionProxyDictionary = [:]
      configuration.proxyConfigurations = []
      configuration.timeoutIntervalForRequest = timeoutInterval ?? 5.0

      let session = Alamofire.Session(configuration: configuration)
      let metrics = await session.request(urlConvertible, method: .head).serializingData().response
        .metrics

      guard let transactionMetrics = metrics?.transactionMetrics.first,
        let requestStartDate = transactionMetrics.requestStartDate,
        let responseStartDate = transactionMetrics.responseStartDate
      else {
        return .zero
      }

      return .seconds(requestStartDate.distance(to: responseStartDate))
    }
  }
#endif
