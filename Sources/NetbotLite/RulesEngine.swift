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
import NEAddressProcessing
import NIOCore
import NetbotLiteData
import Synchronization
import SynchronizationExtras
import Tracing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
public protocol RulesEngine: Sendable {

  var forwardingRules: [any ForwardingRuleConvertible] { get }

  func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible])

  func executeAllRules(connection: Connection) async -> ForwardingReport
}

@available(SwiftStdlib 6.0, *)
@Lockable final class DefaultRulesEngine: RulesEngine {

  let logger: Logger

  var forwardingRules: [any ForwardingRuleConvertible] = []

  let cache = LRUCache<String, any ForwardingRule>(capacity: 100)
  private let inFlightLookups = Mutex<[String: Task<ForwardingReport, Never>]>([:])

  init(logger: Logger) {
    self.logger = logger
  }

  func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) {
    $forwardingRules.withLock { $0 = forwardingRules }

    // ForwardingRules has changed, we should reset cache.
    cache.removeAllValues()
  }

  func executeAllRules(connection: Connection) async -> ForwardingReport {
    let earliestBeginDate = Date.now
    let startTime = ContinuousClock.now
    guard let originalRequest = connection.originalRequest,
      let host = originalRequest.host(percentEncoded: false)
    else {
      return ForwardingReport(
        earliestBeginDate: earliestBeginDate,
        duration: startTime.duration(to: .now),
        forwardingRule: _FinalForwardingRule()
      )
    }

    let savedForwardingRule = cache.value(forKey: host)

    if let savedForwardingRule {
      return ForwardingReport(
        earliestBeginDate: earliestBeginDate,
        duration: startTime.duration(to: .now),
        forwardingRule: savedForwardingRule
      )
    }

    // Keep in-flight rule lookup tasks so concurrent identical lookups share one operation.
    let task = inFlightLookups.withLock {
      if let task = $0[host] {
        return task
      }

      let task = Task<ForwardingReport, Never> {
        var savedForwardingRule: (any ForwardingRule)?
        var finalForwardingRule: any FinalForwardingRule = _FinalForwardingRule()
        let forwardingRules = $forwardingRules.withLock { $0 }
        for forwardingRule in forwardingRules {
          let forwardingRule = forwardingRule.asForwardingRule()

          if let converted = forwardingRule as? (any FinalForwardingRule) {
            finalForwardingRule = converted
          }

          do {
            if try connection.satisfy(predicate: forwardingRule.predicate) {
              savedForwardingRule = forwardingRule
              // Break the loop bacause we only care about the rule found first
              // that has a higher priority.
              break
            }
          } catch {
            continue
          }
        }

        let forwardingRule = savedForwardingRule ?? finalForwardingRule
        cache.setValue(forwardingRule, forKey: host)

        // We have updated lookup cache, so the task is no longer needed.
        inFlightLookups.withLock { $0[host] = nil }
        return ForwardingReport(
          earliestBeginDate: earliestBeginDate,
          duration: startTime.duration(to: .now),
          forwardingRule: forwardingRule
        )
      }
      $0[host] = task
      return task
    }

    // We cache task here, so we need update `earliestBeginDate` and `duration`
    // to prevent cache value.
    var report = await task.value
    report.earliestBeginDate = earliestBeginDate
    report.duration = startTime.duration(to: .now)

    return report
  }
}

@available(SwiftStdlib 6.0, *)
extension ForwardingReport {
  init(earliestBeginDate: Date, duration: Duration, forwardingRule: any ForwardingRule) {
    let forwardProtocol = forwardingRule.forwardProtocol.asForwardProtocol()
    self.init(
      earliestBeginDate: earliestBeginDate,
      duration: duration,
      forwardProtocol: forwardProtocol.name,
      forwardingRule: forwardingRule.description
    )
    self._forwardingRule = forwardingRule
    self._forwardProtocol = forwardProtocol
  }

  init(earliestBeginDate: Date, duration: Duration, forwardProtocol: any ForwardProtocol) {
    self.init(
      earliestBeginDate: earliestBeginDate,
      duration: duration,
      forwardProtocol: forwardProtocol.name,
      forwardingRule: nil
    )
    self._forwardProtocol = forwardProtocol
  }
}
