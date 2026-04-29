// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2026 Junfeng Zhang and the Netbot project authors
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
public protocol RulesEngine: Sendable {

  var forwardingRules: [any ForwardingRuleConvertible] { get }

  func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible])

  func executeAllRules(connection: Connection) async -> ForwardingReport
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@Lockable final class DefaultRulesEngine: RulesEngine {

  let logger: Logger

  var forwardingRules: [any ForwardingRuleConvertible]

  let cache = LRUCache<String, any ForwardingRule>(capacity: 100)
  private let inFlightLookups = Mutex<[String: Task<ForwardingReport, Never>]>([:])

  init(logger: Logger) {
    self.logger = logger
    self._forwardingRules = .init([])
  }

  func setForwardingRules(_ forwardingRules: [any ForwardingRuleConvertible]) {
    _forwardingRules.withLock { $0 = forwardingRules }

    // ForwardingRules has changed, we should reset cache.
    cache.removeAllValues()
  }

  func executeAllRules(connection: Connection) async -> ForwardingReport {
    guard let originalRequest = connection.originalRequest,
      let host = originalRequest.host(percentEncoded: false)
    else {
      return ForwardingReport(forwardingRule: _FinalForwardingRule())
    }

    let savedForwardingRule = cache.value(forKey: host)

    if let savedForwardingRule {
      return ForwardingReport(forwardingRule: savedForwardingRule)
    }

    // Keep in-flight rule lookup tasks so concurrent identical lookups share one operation.
    let task = inFlightLookups.withLock {
      if let task = $0[host] {
        return task
      }

      let task = Task<ForwardingReport, Never> {
        var savedForwardingRule: (any ForwardingRule)?
        var finalForwardingRule: any FinalForwardingRule = _FinalForwardingRule()
        let forwardingRules = _forwardingRules.withLock { $0 }
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
        return ForwardingReport(forwardingRule: forwardingRule)
      }
      $0[host] = task
      return task
    }
    return await task.value
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardingReport {
  init(duration: Double = 0, forwardingRule: any ForwardingRule) {
    let forwardProtocol = forwardingRule.forwardProtocol.asForwardProtocol()
    self.init(
      duration: duration,
      forwardProtocol: forwardProtocol.name,
      forwardingRule: forwardingRule.description
    )
    self._forwardingRule = forwardingRule
    self._forwardProtocol = forwardProtocol
  }

  init(duration: Double = 0, forwardProtocol: any ForwardProtocol) {
    self.init(duration: duration, forwardProtocol: forwardProtocol.name)
    self._forwardProtocol = forwardProtocol
  }
}
