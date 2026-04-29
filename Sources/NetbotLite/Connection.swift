// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import Dispatch
import Logging
import NEAddressProcessing
import NIOCore
import NetbotLiteData
import Tracing

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  import NIOConcurrencyHelpers
#else
  import Synchronization
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Connection {

  internal var metadata: Logger.Metadata {
    ["Request": "#\(taskIdentifier) \(originalRequest?.address.map { "\($0)" } ?? "unknown host")"]
  }

  func satisfy(predicate: (Connection) throws -> Bool) rethrows -> Bool {
    try predicate(self)
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Connection.State {
  var isFinished: Bool {
    switch self {
    case .establishing, .active:
      return false
    case .completed, .failed, .cancelled:
      return true
    }
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Connection {

  private func processInfoLookup(logger: Logger, proc: any ProcessReporting) async throws {
    // We don't care error of process report generating, so we can use optional try.
    try? await withSpan("process-report gen") { _ in
      assert(establishmentReport != nil)
      guard establishmentReport?.sourceEndpoint != nil else {
        return
      }
      processReport = try await proc.processInfo(connection: self)
    }
  }

  /// Performs DNS resolution for the connection's original request and updates the session with a DNSResolutionReport.
  ///
  /// This function measures the timing of the DNS resolution process, concurrently queries both AAAA and A DNS records,
  /// and streams partial results into `session._dnsResolutionReport` as they arrive. It handles special cases where
  /// the address is already an IP, a unix or URL address, or missing, producing either an empty report or a cache-sourced
  /// resolution accordingly. Completion is signaled via a promise and the function returns only after at least one query
  /// path has produced a result (or both have failed). The entire process runs within a tracing span named "dns query".
  ///
  private func dnsLookup(logger: Logger, resolver: any Resolver, on eventLoop: any EventLoop)
    async throws
  {
    try await withSpan("dns query") { _ in
      let startTime = DispatchTime.now()
      let hostname: String
      guard let address = originalRequest?.address, let port = originalRequest?.port
      else {
        dnsResolutionReport = DNSResolutionReport(
          duration: startTime.distance(to: .now()).timeInterval,
          resolutions: []
        )
        return
      }

      switch address {
      case .hostPort(let host, _):
        switch host {
        case .name(let name):
          hostname = name
        case .ipv4, .ipv6:
          dnsResolutionReport = DNSResolutionReport(
            duration: startTime.distance(to: .now()).timeInterval,
            resolutions: [
              DNSResolutionReport.Resolution(
                source: .cache,
                duration: startTime.distance(to: .now()).timeInterval,
                dnsProtocol: .unknown,
                endpoints: [address]
              )
            ]
          )
          return
        }
      case .unix:
        dnsResolutionReport = DNSResolutionReport(
          duration: startTime.distance(to: .now()).timeInterval,
          resolutions: []
        )
        return
      case .url:
        // Not supported yet.
        dnsResolutionReport = DNSResolutionReport(
          duration: startTime.distance(to: .now()).timeInterval,
          resolutions: []
        )
        return
      }

      // Do actual query in a separated task the promise wait until
      // first success result received.
      let promise = eventLoop.makePromise(of: Void.self)
      Task {
        try await withThrowingTaskGroup(
          of: Result<[DNSResolutionReport.Resolution], any Error>.self
        ) { g in
          g.addTask {
            do {
              let startTime = DispatchTime.now()
              let addresses = try await resolver.initiateAAAAQuery(host: hostname, port: port)
                .get()

              return .success([
                DNSResolutionReport.Resolution(
                  source: .query,
                  duration: startTime.distance(to: .now()).timeInterval,
                  dnsProtocol: .udp,
                  endpoints: addresses.compactMap { try? $0.asAddress() }
                )
              ])
            } catch {
              return .failure(error)
            }
          }

          g.addTask {
            do {
              let startTime = DispatchTime.now()
              let addresses = try await resolver.initiateAQuery(host: hostname, port: port)
                .get()

              return .success([
                DNSResolutionReport.Resolution(
                  source: .query,
                  duration: startTime.distance(to: .now()).timeInterval,
                  dnsProtocol: .udp,
                  endpoints: addresses.compactMap { try? $0.asAddress() }
                )
              ])
            } catch {
              return .failure(error)
            }
          }

          var lastError: (any Error)?

          // There is no error for for-in loop, so we don't need handle this.
          for try await resolution in g {
            do {
              let resolutions: [DNSResolutionReport.Resolution] = try resolution.get()
              _dnsResolutionReport.withLock {
                if $0 == nil {
                  $0 = DNSResolutionReport(duration: 0, resolutions: resolutions)
                } else {
                  $0?.resolutions.append(contentsOf: resolutions)
                }
              }
              promise.succeed()
            } catch {
              if lastError != nil {
                // Failed to query both A and AAAA records.
                throw error
              }
              lastError = error
            }
          }

          if let lastError {
            if dnsResolutionReport?.resolutions.isEmpty ?? false {
              throw lastError
            }
          }
        }
      }
      try await promise.futureResult.get()

      logger.debug(
        "DNS evaluating end with \(startTime.distance(to: .now()).prettyPrinted).",
        metadata: metadata
      )
    }
  }

  private func ruleLookup(logger: Logger, rulesEngine: any RulesEngine) async throws {
    await withSpan("forwarding-rule lookup") { _ in
      let startTime = DispatchTime.now()

      var forwardingReport = await rulesEngine.executeAllRules(connection: self)
      let duration = startTime.distance(to: .now())
      forwardingReport._duration = duration.timeInterval
      assert(forwardingReport._forwardingRule != nil)
      assert(forwardingReport._forwardProtocol != nil)
      self.forwardingReport = forwardingReport

      logger.debug(
        "Rule evaluating end with \(duration.prettyPrinted).",
        metadata: metadata
      )
      logger.debug(
        "Rule matched - \(forwardingReport.forwardingRule ?? "FINAL")", metadata: metadata)
    }
  }

  func evalProtocolLookup(
    logger: Logger, outboundMode: OutboundMode, forwardProtocol: any ForwardProtocolConvertible,
    proc: any ProcessReporting, resolver: any Resolver, rules: any RulesEngine,
    on eventLoop: any EventLoop
  ) async throws {
    try await withSpan("forward-protocol lookup") { _ in
      try await withThrowingTaskGroup(of: Void.self) { g in
        g.addTask {
          try await self.processInfoLookup(logger: logger, proc: proc)
        }
        g.addTask {
          try await self.dnsLookup(logger: logger, resolver: resolver, on: eventLoop)
        }
        try await g.waitForAll()
      }

      let fallback: any ForwardProtocol
      let startTime = DispatchTime.now()

      switch outboundMode {
      case .direct:
        fallback = .direct
        forwardingReport = ForwardingReport(
          duration: startTime.distance(to: .now()).timeInterval,
          forwardProtocol: fallback
        )
      case .globalProxy:
        fallback = forwardProtocol.asForwardProtocol()
        forwardingReport = ForwardingReport(
          duration: startTime.distance(to: .now()).timeInterval,
          forwardProtocol: fallback
        )
      case .ruleBased:
        try await self.ruleLookup(logger: logger, rulesEngine: rules)
        assert(forwardingReport?._forwardProtocol != nil)
        assert(forwardingReport?._forwardingRule != nil)
        fallback = forwardingReport?._forwardProtocol as? any ForwardProtocol ?? .direct
      }

      if fallback is any ProxiableForwardProtocol {
        _establishmentReport.withLock {
          assert($0 != nil)
          $0?.usedProxy = true
        }
      }

      logger.debug(
        "Policy evaluating - \(fallback.name)",
        metadata: metadata
      )
    }
  }

  func publish(with publisher: any ConnectionPublisher) async {
    Task {
      // Publish initial state of session.
      await publisher.send(self)

      repeat {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        _duration += 1

        // Publish session changes.
        await publisher.send(self)
      } while !state.isFinished

      // Reset the data transfer report metrics and publish changes.
      _dataTransferReport.withLock { $0?.pathReport = .init() }
      await publisher.send(self)
    }
  }

  func collectDataTransferMetrics(on channel: any Channel) async {
    Task {
      assert(dataTransferReport == nil)

      repeat {
        guard let collector = try? await channel.pendingDataTransferReport().get() else {
          // There are two situations that prevent us from geting the pending
          // data transfer report, The first is that the channel has been closed,
          // and the second is that the channel.connection is missing. Both
          // situations indicate that the connection has ended, so we mark it
          // `completed` here.
          _duration = -earliestBeginDate.timeIntervalSinceNow
          state = .completed
          break
        }

        try await Task.sleep(nanoseconds: 1_000_000_000)
        let currentDataTransferReport = try await channel.dataTransferReport(collector)
          .get()
        if let dataTransferReport {
          self.dataTransferReport = .init(
            duration: dataTransferReport._duration + currentDataTransferReport._duration,
            aggregatePathReport: dataTransferReport.aggregatePathReport
              &+ currentDataTransferReport.aggregatePathReport,
            pathReport: currentDataTransferReport.aggregatePathReport
          )
        } else {
          dataTransferReport = .init(
            duration: currentDataTransferReport._duration,
            aggregatePathReport: currentDataTransferReport.aggregatePathReport,
            pathReport: currentDataTransferReport.aggregatePathReport
          )
        }
      } while !state.isFinished
    }
  }
}
