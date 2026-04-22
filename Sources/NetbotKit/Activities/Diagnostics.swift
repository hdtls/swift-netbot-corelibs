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

#if os(macOS)
  import Alamofire
  import Dispatch
  import Foundation
  import Logging
  import Network

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.7, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  final public class Diagnostics: Sendable {

    private let logger = Logger(label: "com.tenbits.diagnostics")

    nonisolated public init() {
    }

    /// Measure latency for Router, DNS and Internet.
    #if swift(>=6.2)
      /// Measure TCP connect time to port 53.
      @concurrent public func testRouterLatency(address: NWEndpoint.Host) async -> Duration {
        await _testRouterLatency(address: address)
      }

      /// Measure Internet latency by fetching a tiny known endpoint (defaults to Apple's connectivity check) with a HEAD request.
      ///
      /// - Parameters:
      ///   - connectivityCheckURL: The URL used to measure connectivity.
      ///   - timeoutInterval: The timeout time interval for measure request.
      /// - Returns: A tuple of duration of dns request/response circle and duration of TTFB.
      ///
      @concurrent public func testDNSLatency(url: URL? = nil, timeoutInterval: Double? = nil) async
        -> Duration
      {
        await _testDNSLatency(url: url, timeoutInterval: timeoutInterval)
      }

      /// Measure Internet latency by fetching a tiny known endpoint (defaults to Apple's connectivity check) with a HEAD request.
      ///
      /// - Parameters:
      ///   - connectivityCheckURL: The URL used to measure connectivity.
      ///   - timeoutInterval: The timeout time interval for measure request.
      /// - Returns: A tuple of duration of dns request/response circle and duration of TTFB.
      ///
      @concurrent public func testInternetLatency(url: URL? = nil, timeoutInterval: Double? = nil)
        async -> Duration
      {
        await _testInternetLatency(url: url, timeoutInterval: timeoutInterval)
      }
    #else
      nonisolated public func testRouterLatency(address: NWEndpoint) async -> Duration {
        await _testRouterLatency(address: address)
      }

      nonisolated public func testDNSLatency(url: URL? = nil, timeoutInterval: Double? = nil) async
        -> Duration
      {
        await _testDNSLatency(url: url, timeoutInterval: timeoutInterval)
      }

      nonisolated public func testInternetLatency(url: URL? = nil, timeoutInterval: Double? = nil)
        async -> Duration
      {
        await _testInternetLatency(url: url, timeoutInterval: timeoutInterval)
      }
    #endif

    nonisolated private func _testRouterLatency(address: NWEndpoint.Host) async -> Duration {
      await withCheckedContinuation { continuation in
        let connection = NWConnection(to: .hostPort(host: address, port: 53), using: .tcp)

        let timeoutTask = Task {
          try await Task.sleep(for: .seconds(5))
          try Task.checkCancellation()

          guard case .ready = connection.state else {
            connection.forceCancel()
            continuation.resume(returning: .seconds(.greatestFiniteMagnitude))
            return
          }
        }

        let startTime: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }

        connection.stateUpdateHandler = {
          guard case .ready = $0 else {
            return
          }
          let endTime: Date = if #available(SwiftStdlib 5.5, *) { .now } else { .init() }
          continuation.resume(returning: .seconds(startTime.distance(to: endTime)))
          timeoutTask.cancel()
          connection.forceCancel()
        }
        connection.start(queue: .global())
      }
    }

    nonisolated private func _testDNSLatency(url: URL? = nil, timeoutInterval: Double? = nil) async
      -> Duration
    {
      let urlConvertible = url?.absoluteString ?? "https://captive.apple.com/hotspot-detect.html"

      let configuration = URLSessionConfiguration.default
      configuration.connectionProxyDictionary = [:]
      #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
        if #available(SwiftStdlib 5.9, *) {
          configuration.proxyConfigurations = []
        }
      #else
        configuration.proxyConfigurations = []
      #endif
      configuration.timeoutIntervalForRequest = timeoutInterval ?? 5.0

      let session = Session(configuration: configuration)
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

    nonisolated private func _testInternetLatency(url: URL? = nil, timeoutInterval: Double? = nil)
      async -> Duration
    {
      let urlConvertible = url?.absoluteString ?? "https://captive.apple.com/hotspot-detect.html"

      let configuration = URLSessionConfiguration.default
      configuration.connectionProxyDictionary = [:]
      #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
        if #available(SwiftStdlib 5.9, *) {
          configuration.proxyConfigurations = []
        }
      #else
        configuration.proxyConfigurations = []
      #endif
      configuration.timeoutIntervalForRequest = timeoutInterval ?? 5.0

      let session = Session(configuration: configuration)
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
