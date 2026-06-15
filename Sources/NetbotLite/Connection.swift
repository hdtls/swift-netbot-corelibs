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

import Dispatch
import Logging
import NEAddressProcessing
import NIOCore
import NetbotLiteData
import Synchronization
import Tracing

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

@available(SwiftStdlib 6.0, *)
extension Connection {

  internal var metadata: Logger.Metadata {
    ["Request": "#\(taskIdentifier) \(originalRequest?.address.map { "\($0)" } ?? "unknown host")"]
  }

  func satisfy(predicate: (Connection) throws -> Bool) rethrows -> Bool {
    try predicate(self)
  }
}

@available(SwiftStdlib 6.0, *)
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

@available(SwiftStdlib 6.0, *)
extension Connection {

  func processInfoLookup(logger: Logger, proc: any ProcessReporting) async throws {
    // We don't care error of process report generating, so we can use optional try.
    try await withSpan("process-report gen") { span in
      assert(establishmentReport != nil)
      guard establishmentReport?.sourceEndpoint != nil else {
        return
      }

      processReport = try await proc.processInfo(connection: self)

      span.updateAttributes { attributes in
        attributes["process.id"] = processReport?.processIdentifier
        attributes["process.program.name"] = processReport?.program?.localizedName
        attributes["process.program.executable"] =
          processReport?.program?.executableURL?.absoluteString
        attributes["process.program.bundle"] = processReport?.program?.bundleURL?.absoluteString
      }
      span.setStatus(.init(code: .ok))
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
  func dnsLookup(logger: Logger, resolver: any Resolver, on eventLoop: any EventLoop) async throws {
    try await withSpan("dns query") { span in
      let earliestBeginDate = Date.now
      let startTime = DispatchTime.now()

      let address = originalRequest?.address
      let port = originalRequest?.port ?? 0

      let dnsResolutionReport: DNSResolutionReport
      switch address {
      case .hostPort(let host, _):
        switch host {
        case .name(let hostname):
          // Do actual query in a separated task the promise wait until
          // first success result received.
          let promise = eventLoop.makePromise(of: Void.self)
          Task {
            await withTaskGroup(of: Result<[DNSResolutionReport.Resolution], any Error>.self) { g in
              g.addTask {
                do {
                  let startTime = DispatchTime.now()
                  let addresses = try await resolver.initiateAAAAQuery(host: hostname, port: port)
                    .get()

                  return .success([
                    DNSResolutionReport.Resolution(
                      source: .query,
                      duration: startTime.distance(to: .now()).duration,
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
                      duration: startTime.distance(to: .now()).duration,
                      dnsProtocol: .udp,
                      endpoints: addresses.compactMap { try? $0.asAddress() }
                    )
                  ])
                } catch {
                  return .failure(error)
                }
              }

              var lastError: (any Error)?

              for await resolution in g {
                do {
                  let resolutions: [DNSResolutionReport.Resolution] = try resolution.get()
                  guard !resolutions.map(\.endpoints).joined().isEmpty else { continue }
                  withMutation(keyPath: \.dnsResolutionReport) {
                    $dnsResolutionReport.withLock {
                      if $0 == nil {
                        $0 = DNSResolutionReport(
                          earliestBeginDate: earliestBeginDate,
                          duration: .zero,
                          resolutions: resolutions
                        )
                      } else {
                        $0?.resolutions.append(contentsOf: resolutions)
                      }
                    }
                  }
                  promise.succeed()
                } catch {
                  lastError = error
                }
              }

              if let lastError {
                // Failed when both DNS resolutions is empty and an error is occured.
                access(keyPath: \.dnsResolutionReport)
                if $dnsResolutionReport.withLock({ $0?.resolutions.isEmpty ?? true }) {
                  promise.fail(lastError)
                }
              }
            }
          }
          try await promise.futureResult.get()
          // Once resolution completed successfully the `self.dnsResolutionReport`
          dnsResolutionReport = self.dnsResolutionReport!
        case .ipv4, .ipv6:
          dnsResolutionReport = DNSResolutionReport(
            earliestBeginDate: earliestBeginDate,
            duration: startTime.distance(to: .now()).duration,
            resolutions: [
              DNSResolutionReport.Resolution(
                source: .cache,
                duration: startTime.distance(to: .now()).duration,
                dnsProtocol: .unknown,
                endpoints: [address!]
              )
            ]
          )
        }
      case .unix:
        dnsResolutionReport = DNSResolutionReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.distance(to: .now()).duration,
          resolutions: []
        )
      case .url:
        // Not supported yet.
        dnsResolutionReport = DNSResolutionReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.distance(to: .now()).duration,
          resolutions: []
        )
      case .none:
        dnsResolutionReport = DNSResolutionReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.distance(to: .now()).duration,
          resolutions: []
        )
      }

      self.dnsResolutionReport = dnsResolutionReport

      logger.debug(
        "DNS evaluating end with \(dnsResolutionReport.duration.formatted(.prettyPrinted())).",
        metadata: metadata
      )

      span.updateAttributes { attributes in
        attributes["dns.query.earliest_begin_date"] = dnsResolutionReport.earliestBeginDate
          .formatted()
        attributes["dns.query.duration"] = dnsResolutionReport.duration.seconds
        attributes["dns.query.resolutions"] = dnsResolutionReport.resolutions.count
      }
      span.setStatus(.init(code: .ok))
    }
  }

  func ruleLookup(logger: Logger, rulesEngine: any RulesEngine) async throws {
    await withSpan("forwarding-rule lookup") { span in
      let report = await rulesEngine.executeAllRules(connection: self)
      assert(report._forwardingRule != nil)
      assert(report._forwardProtocol != nil)
      forwardingReport = report

      logger.debug(
        "Rule evaluating end with \(report.duration.formatted(.prettyPrinted())).",
        metadata: metadata
      )
      logger.debug("Rule matched - \(report.forwardingRule ?? "FINAL")", metadata: metadata)

      span.updateAttributes { attributes in
        attributes["rule.lookup.earliest_begin_date"] = report.earliestBeginDate.formatted()
        attributes["rule.lookup.duration"] = report.duration.seconds
        attributes["rule.forward_protocol"] = report.forwardProtocol
        attributes["rule.description"] = report.forwardingRule
      }
      span.setStatus(.init(code: .ok))
    }
  }

  func protocolLookup(
    logger: Logger, outboundMode: OutboundMode, forwardProtocol: any ForwardProtocolConvertible,
    proc: any ProcessReporting, resolver: any Resolver, rules: any RulesEngine,
    eventLoop: any EventLoop
  ) async throws {
    try await withSpan("forward-protocol lookup") { span in
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
      let earliestBeginDate = Date.now
      let startTime = DispatchTime.now()

      switch outboundMode {
      case .direct:
        fallback = .direct
        forwardingReport = ForwardingReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.distance(to: .now()).duration,
          forwardProtocol: fallback
        )
      case .globalProxy:
        fallback = forwardProtocol.asForwardProtocol()
        forwardingReport = ForwardingReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.distance(to: .now()).duration,
          forwardProtocol: fallback
        )
      case .ruleBased:
        try await self.ruleLookup(logger: logger, rulesEngine: rules)
        assert(forwardingReport?._forwardProtocol != nil)
        assert(forwardingReport?._forwardingRule != nil)
        fallback = forwardingReport?._forwardProtocol as? any ForwardProtocol ?? .direct
      }

      if fallback is any ProxiableForwardProtocol {
        withMutation(keyPath: \.establishmentReport) {
          $establishmentReport.withLock {
            assert($0 != nil)
            $0?.usedProxy = true
          }
        }
      }

      logger.debug(
        "Policy evaluating - \(fallback.name)",
        metadata: metadata
      )

      span.updateAttributes { attributes in
        attributes["forwarder.lookup.earliest_begin_date"] = earliestBeginDate.formatted()
        attributes["forwarder.lookup.duration"] = startTime.distance(to: .now()).duration.seconds
        attributes["forwarder.protocol"] = fallback.name
      }
      span.setStatus(.init(code: .ok))
    }
  }

  func publish(using publisher: any ConnectionPublisher) async {
    @Sendable func finish() async {
      // Reset the data transfer report metrics and publish changes.
      $dataTransferReport.withLock { $0?.pathReport = .init() }
      await publisher.send(self)
    }

    Task.detached {
      while true {
        try? await Task.sleep(for: .seconds(1))
        guard !self.state.isFinished else {
          #if !canImport(Darwin) && swift(<6.3)
            await finish()
          #endif
          break
        }
        self.duration += .seconds(1)
        #if !canImport(Darwin) && swift(<6.3)
          await publisher.send(self)
        #endif
      }
    }

    #if canImport(Darwin) || swift(>=6.3)
      Task {
        if #available(SwiftStdlib 6.2, *) {
          let observations = Observations<Void, Never>.untilFinished {
            guard !self.state.isFinished else {
              return .finish
            }
            _ = (
              self.currentRequest,
              self.response,
              self.duration,
              self.tls,
              self.state,
              self.dnsResolutionReport,
              self.establishmentReport,
              self.forwardingReport,
              self.dataTransferReport,
              self.processReport
            )
            return .next(())
          }
          for await _ in observations {
            await publisher.send(self)
          }
          await finish()
        } else {
          let observations = AsyncStream<Void>(
            bufferingPolicy: .bufferingNewest(1)
          ) { continuation in
            @Sendable func installTracking() {
              withObservationTracking {
                _ = (
                  self.currentRequest,
                  self.response,
                  self.duration,
                  self.tls,
                  self.state,
                  self.dnsResolutionReport,
                  self.establishmentReport,
                  self.forwardingReport,
                  self.dataTransferReport,
                  self.processReport
                )
              } onChange: {
                guard !self.state.isFinished else {
                  continuation.finish()
                  return
                }
                continuation.yield()
                installTracking()
              }
            }
            installTracking()
          }
          for await _ in observations {
            await publisher.send(self)
          }
          await finish()
        }
      }
    #endif
  }

  func collectDataTransferMetrics(on channel: any Channel) async {
    Task {
      assert(dataTransferReport == nil)
      while !self.state.isFinished {
        guard let collector = try? await channel.pendingDataTransferReport().get() else {
          // There are two situations that prevent us from geting the pending
          // data transfer report, The first is that the channel has been closed,
          // and the second is that the channel.connection is missing. Both
          // situations indicate that the connection has ended, so we mark it
          // `completed` here.
          if !state.isFinished {
            duration = .seconds(-earliestBeginDate.timeIntervalSinceNow)
            state = .completed
          }
          break
        }

        try? await Task.sleep(for: .seconds(1))

        // We don't care about failure here ignore errors by optional try.
        guard let new = try? await channel.dataTransferReport(collector).get() else {
          continue
        }

        guard let dataTransferReport else {
          self.dataTransferReport = new
          continue
        }

        self.dataTransferReport = .init(
          duration: dataTransferReport.duration + new.duration,
          aggregatePathReport: dataTransferReport.aggregatePathReport &+ new.aggregatePathReport,
          pathReport: self.state.isFinished ? .init() : new.aggregatePathReport
        )
      }
    }
  }
}
