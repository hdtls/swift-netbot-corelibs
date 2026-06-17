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

import Logging
import Metrics
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
extension Optional where Wrapped == ForwardingReport {
  func asForwardProtocol() -> any ForwardProtocol {
    switch self {
    case .none:
      return .direct
    case .some(let wrapped):
      return wrapped._forwardProtocol as? ForwardProtocol ?? .direct
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension Result {

  init(catching body: @Sendable () async throws(Failure) -> Success) async {
    do {
      let value = try await body()
      self = .success(value)
    } catch {
      self = .failure(error)
    }
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

  internal var metadata: Logger.Metadata {
    ["Request": "#\(taskIdentifier) \(originalRequest?.address.map { "\($0)" } ?? "unknown host")"]
  }

  func satisfy(predicate: (Connection) throws -> Bool) rethrows -> Bool {
    try predicate(self)
  }
}

@available(SwiftStdlib 6.0, *)
extension Connection {

  func establishmentMetrics(on outputStream: any Channel) async {
    @inline(__always) func execute() async -> EstablishmentReport? {
      // Once channel connected, we can request establishment report.
      // Error will be ignored, we don't want connection closed by establishment report
      // generation error.
      let establishmentReport = try? await outputStream.establishmentReport().get()
      if let establishmentReport {
        withMutation(keyPath: \.establishmentReport) {
          $establishmentReport.withLock {
            // `EstablishmentReport.sourceEndpoint` is requested from server channel, but
            // establishment report is requested from client channel, so we need update sourceEndpoint
            // to use original value.
            let usedProxy = $0?.usedProxy ?? false

            $0?.duration = establishmentReport.duration
            $0?.attemptStartedAfterInterval = establishmentReport.attemptStartedAfterInterval
            $0?.previousAttemptCount = establishmentReport.previousAttemptCount
            $0?.proxyEndpoint = usedProxy ? (try? outputStream.remoteAddress?.asAddress()) : nil
            $0?.resolutions = establishmentReport.resolutions
          }
        }
      }
      return establishmentReport
    }

    await withSpan("task.establishment-report gen") { span in
      let label = "task.establishment-report-gen.duration"
      let dimensions = [
        ("task.id", "\(id)"),
        ("task.establishment-report-gen.earliest_begin_date", Date.now.formatted()),
      ]
      let metrics = await Timer.measure(label: label, dimensions: dimensions) {
        await execute()
      }

      span.updateAttributes { attributes in
        attributes["establishment.use_proxy"] = metrics?.usedProxy
        attributes["establishment.duration"] = metrics?.duration.seconds
        attributes["establishment.resolutions"] = metrics?.resolutions.count
      }
      span.setStatus(.init(code: .ok))
    }
  }

  func processLookup(logger: Logger, proc: any ProcessReporting) async throws {
    // We don't care error of process report generating, so we can use optional try.
    guard establishmentReport?.sourceEndpoint != nil else {
      return
    }

    @inline(__always) func execute() async throws -> ProcessReport? {
      let metrics = try await proc.processInfo(connection: self)
      processReport = metrics
      return metrics
    }

    try await withSpan("task.process-lookup") { span in
      let label = "task.process-lookup.duration"
      let dimensions = [
        ("task.id", "\(id)"),
        ("task.process-lookup.earliest_begin_date", Date.now.formatted()),
      ]
      let metrics = try await Timer.measure(label: label, dimensions: dimensions) {
        try await execute()
      }

      span.updateAttributes { attributes in
        attributes["process.id"] = metrics?.processIdentifier
        attributes["process.program.name"] = metrics?.program?.localizedName
        attributes["process.program.executable"] = metrics?.program?.executableURL?.absoluteString
        attributes["process.program.bundle"] = metrics?.program?.bundleURL?.absoluteString
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
    @inline(__always) func execute() async throws -> DNSResolutionReport? {
      let earliestBeginDate = Date.now
      let startTime = ContinuousClock.now

      let address = originalRequest?.address
      let port = originalRequest?.port ?? 0

      let metrics: DNSResolutionReport
      switch address {
      case .hostPort(let host, _):
        switch host {
        case .name(let hostname):
          // Do actual query in a separated task the promise wait until
          // first success result received.
          let promise = eventLoop.makePromise(of: Void.self)
          Task {
            await withTaskGroup(of: Result<DNSResolutionReport.Resolution, any Error>.self) { g in
              g.addTask {
                await Result {
                  DNSResolutionReport.Resolution(
                    source: .query,
                    duration: startTime.duration(to: .now),
                    dnsProtocol: .udp,
                    endpoints:
                      try await resolver
                      .initiateAAAAQuery(host: hostname, port: port)
                      .flatMapThrowing({ try $0.map({ try $0.asAddress() }) })
                      .get()
                  )
                }
              }

              g.addTask {
                await Result {
                  DNSResolutionReport.Resolution(
                    source: .query,
                    duration: startTime.duration(to: .now),
                    dnsProtocol: .udp,
                    endpoints:
                      try await resolver
                      .initiateAQuery(host: hostname, port: port)
                      .flatMapThrowing({ try $0.map({ try $0.asAddress() }) })
                      .get()
                  )
                }
              }

              var lastError: (any Error)?
              // False if any resolution contains at least one endpoint.
              var isEmpty = true

              for await result in g {
                do {
                  let resolution = try result.get()
                  guard !resolution.endpoints.isEmpty else { continue }

                  withMutation(keyPath: \.dnsResolutionReport) {
                    $dnsResolutionReport.withLock {
                      if $0 == nil {
                        $0 = DNSResolutionReport(
                          earliestBeginDate: earliestBeginDate,
                          duration: startTime.duration(to: .now),
                          resolutions: [resolution]
                        )
                      } else {
                        $0?.resolutions.append(resolution)
                      }
                    }
                  }

                  // Fulfill promise immediately after first non-empty result is arrived.
                  promise.succeed()
                  isEmpty = false
                } catch {
                  lastError = error
                }
              }

              // Ensure we got DNS resolution report whatever success or failed.
              withMutation(keyPath: \.dnsResolutionReport) {
                $dnsResolutionReport.withLock {
                  if $0 == nil {
                    $0 = .init(
                      earliestBeginDate: earliestBeginDate,
                      duration: startTime.duration(to: .now),
                      resolutions: []
                    )
                  } else {
                    $0?.duration = startTime.duration(to: .now)
                  }
                }
              }

              // Failed when both DNS resolutions is empty and an error is occured.
              if let lastError, isEmpty {
                promise.fail(lastError)
              }

              // This is required to resume event loop for no
              // endpoints contains in all queries.
              promise.succeed()
            }
          }
          try await promise.futureResult.get()
          metrics = self.dnsResolutionReport!
        case .ipv4, .ipv6:
          metrics = DNSResolutionReport(
            earliestBeginDate: earliestBeginDate,
            duration: startTime.duration(to: .now),
            resolutions: [
              DNSResolutionReport.Resolution(
                source: .cache,
                duration: startTime.duration(to: .now),
                dnsProtocol: .unknown,
                endpoints: [address!]
              )
            ]
          )
        }
      case .unix:
        metrics = DNSResolutionReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.duration(to: .now),
          resolutions: []
        )
      case .url:
        // Not supported yet.
        metrics = DNSResolutionReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.duration(to: .now),
          resolutions: []
        )
      case .none:
        metrics = DNSResolutionReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.duration(to: .now),
          resolutions: []
        )
      }

      dnsResolutionReport = metrics

      logger.debug(
        "DNS evaluating end with \(metrics.duration.formatted(.prettyPrinted())).",
        metadata: metadata
      )
      return metrics
    }

    try await withSpan("task.dns-query") { span in
      let label = "task.dns-query.duration"
      let dimensions = $originalRequest.withLock {
        [
          ("task.id", "\(id)"),
          ("task.original_request.address", $0?.address.map({ "\($0)" }) ?? "nil"),
          ("task.original_request.port", "\($0?.port ?? 0)"),
          ("task.dns-query.earliest_begin_date", earliestBeginDate.formatted()),
        ]
      }
      let metrics = try await Timer.measure(label: label, dimensions: dimensions) {
        try await execute()
      }

      span.updateAttributes { attributes in
        attributes["dns.query.earliest_begin_date"] = metrics?.earliestBeginDate.formatted()
        attributes["dns.query.duration"] = metrics?.duration.seconds
        attributes["dns.query.resolutions"] = metrics?.resolutions.count
      }
      span.setStatus(.init(code: .ok))
    }
  }

  func ruleLookup(logger: Logger, rulesEngine: any RulesEngine) async throws {
    @inline(__always) func execute() async -> ForwardingReport? {
      let metrics = await rulesEngine.executeAllRules(connection: self)
      assert(metrics._forwardingRule != nil)
      assert(metrics._forwardProtocol != nil)
      forwardingReport = metrics

      logger.debug(
        "Rule evaluating end with \(metrics.duration.formatted(.prettyPrinted())).",
        metadata: metadata)
      logger.debug("Rule matched - \(metrics.forwardingRule ?? "FINAL")", metadata: metadata)
      return metrics
    }

    await withSpan("task.rule-lookup") { span in
      let label = "task.rule-lookup.duration"
      let dimensions = [
        ("task.id", "\(id)"),
        ("task.rule-lookup.rule_count", "\(rulesEngine.forwardingRules.count)"),
        ("task.rule-lookup.earliest_begin_date", Date.now.formatted()),
      ]
      let metrics = await Timer.measure(label: label, dimensions: dimensions) {
        await execute()
      }

      span.updateAttributes { attributes in
        attributes["rule.lookup.earliest_begin_date"] = metrics?.earliestBeginDate.formatted()
        attributes["rule.lookup.duration"] = metrics?.duration.seconds
        attributes["rule.forward_protocol"] = metrics?.forwardProtocol
        attributes["rule.description"] = metrics?.forwardingRule
      }
      span.setStatus(.init(code: .ok))
    }
  }

  func protocolLookup(
    logger: Logger, outboundMode: OutboundMode, forwardProtocol: any ForwardProtocolConvertible,
    proc: any ProcessReporting, resolver: any Resolver, rules: any RulesEngine,
    eventLoop: any EventLoop
  ) async throws {
    @inline(__always) func execute() async throws -> ForwardingReport? {
      try await withThrowingTaskGroup(of: Void.self) { g in
        g.addTask {
          try await self.processLookup(logger: logger, proc: proc)
        }
        g.addTask {
          try await self.dnsLookup(logger: logger, resolver: resolver, on: eventLoop)
        }
        try await g.waitForAll()
      }

      let earliestBeginDate = Date.now
      let startTime = ContinuousClock.now

      let metrics: ForwardingReport?
      switch outboundMode {
      case .direct:
        metrics = ForwardingReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.duration(to: .now),
          forwardProtocol: .direct
        )
      case .globalProxy:
        metrics = ForwardingReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.duration(to: .now),
          forwardProtocol: forwardProtocol.asForwardProtocol()
        )
      case .ruleBased:
        try await self.ruleLookup(logger: logger, rulesEngine: rules)
        precondition(forwardingReport != nil)
        metrics = forwardingReport!
      }

      forwardingReport = metrics

      let `protocol` = metrics.asForwardProtocol()

      if `protocol` is any ProxiableForwardProtocol {
        $establishmentReport.withLock { $0?.usedProxy = true }
      }

      logger.debug("Policy evaluating - \(`protocol`.name)", metadata: metadata)

      return metrics
    }

    try await withSpan("task.forwarder-lookup") { span in
      let earliestBeginDate = Date.now

      let label = "task.forwarder-lookup.duration"
      let dimensions = [
        ("task.id", "\(id)"),
        ("task.forwarder-lookup.earliest_begin_date", earliestBeginDate.formatted()),
      ]
      let metrics = try await Timer.measure(label: label, dimensions: dimensions) {
        try await execute()
      }

      span.updateAttributes { attributes in
        attributes["forwarder.lookup.earliest_begin_date"] = earliestBeginDate.formatted()
        attributes["forwarder.lookup.duration"] = metrics?.duration.seconds
        attributes["forwarder.protocol"] = metrics.asForwardProtocol().name
      }
      span.setStatus(.init(code: .ok))
    }
  }

  func publish(using publisher: any ConnectionPublisher) async {
    @inline(__always) @Sendable func finish() async {
      // Reset the data transfer report metrics and publish changes.
      $dataTransferReport.withLock { $0?.pathReport = .init() }
      await publisher.send(self)
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
              self.dnsResolutionReport,
              self.establishmentReport,
              self.forwardingReport,
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

  func transportMetrics(on outputStream: (any Channel)?) async {
    transportMetricsTask?.cancel()
    transportMetricsTask = Task { [weak self] in
      guard let self else { return }

      while !Task.isCancelled && !state.isFinished {

        let collector = try? await outputStream?.pendingDataTransferReport().get()

        try? await Task.sleep(for: .seconds(1))

        // We don't care about failure here.
        guard let collector else {
          duration = .seconds(-earliestBeginDate.timeIntervalSinceNow)
          continue
        }

        let new = await collector.collect()

        $dataTransferReport.withLock {
          if $0 == nil {
            $0 = new
          } else {
            $0?.duration += new.duration
            $0?.aggregatePathReport &+= new.aggregatePathReport
            $0?.pathReport = state.isFinished ? .init() : new.aggregatePathReport
          }
        }

        duration = .seconds(-earliestBeginDate.timeIntervalSinceNow)
      }
    }
  }
}
