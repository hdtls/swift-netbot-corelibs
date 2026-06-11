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

#if os(macOS)
  import Foundation
  import Logging
  import Observation
  #if canImport(SwiftUI)
    import SwiftUI
  #endif
  import Network

  @available(SwiftStdlib 6.0, *)
  public struct EventLog: Hashable {
    public var level: Logger.Level
    public var date: Date
    public var message: String

    public init(level: Logger.Level, date: Date, message: String) {
      self.level = level
      self.date = date
      self.message = message
    }
  }

  /// An instance of state object of all activities including latencies, events and Wi-Fi.
  @available(SwiftStdlib 6.0, *)
  @MainActor @Observable final public class Activities {

    /// DNS latency.
    public var dnsLatency = Duration.zero

    #if canImport(SwiftUI)
      /// Formatted DNS latency attributed string.
      public var dnsLatencyAttributed: AttributedString = "-/ms"
    #endif

    /// Router latency.
    public var routerLatency = Duration.zero

    #if canImport(SwiftUI)
      /// Formatted router latency attributed string.
      public var routerLatencyAttributed: AttributedString = "-/ms"
    #endif

    /// Internet latency.
    public var internetLatency = Duration.zero

    #if canImport(SwiftUI)
      /// Formatted internet latency attributed string.
      public var internetLatencyAttributed: AttributedString = "-/ms"
    #endif

    public var events: [EventLog] = []

    /// AirPort state object.
    public let airPort = AirPort()

    /// Diagnostics object.
    private let diagnostics = Diagnostics()

    private let formatStyle = Duration.UnitsFormatStyle.units(
      allowed: [.milliseconds],
      width: .narrow,
      maximumUnitCount: 1
    )

    /// Create a new instance of `Activities`.
    public init() {
      #if canImport(SwiftUI)
        let zero = attributedString(fromDuration: .zero)
        self.dnsLatencyAttributed = zero
        self.routerLatencyAttributed = zero
        self.internetLatencyAttributed = zero
      #endif
    }

    #if canImport(SwiftUI)
      nonisolated private func attributedString(fromDuration duration: Duration) -> AttributedString
      {
        var valuePart: String = "-"
        var unitPart: Substring = "ms"

        // Zero means initial value, max means test failed, both zero and failed should
        // show `-/ms` as result.
        switch duration {
        case .zero, .max:
          break
        case Duration.nanoseconds(1)...Duration.microseconds(999):
          valuePart = "≤1"
        default:
          let formatted = duration.formatted(formatStyle)

          if let unitStartIndex = formatted.firstIndex(where: { !$0.isNumber && $0 != "," }) {
            valuePart = formatted[..<unitStartIndex].trimmingCharacters(in: .whitespaces)
            unitPart = formatted[unitStartIndex...]
          }
        }

        var duration = AttributedString(valuePart)
        duration.font = .system(.title, weight: .bold)

        var unit = AttributedString(unitPart)
        unit.font = .system(.body, weight: .bold)

        return duration + unit
      }
    #endif

    #if swift(>=6.2)
      /// Test latency using specific `url` and `timeoutInterval`.
      ///
      /// This operation update `dnsLatency`, `routerLatency` and `internetLatency` after test finished.
      ///
      /// - Parameters:
      ///   - url: `URL` for internet latency tests.
      ///   - timeoutInterval: Time out interval for all latency tests.
      @concurrent public func testLatency(url: URL? = nil, timeoutInterval: Double = 5) async {
        await _testLatency(url: url, timeoutInterval: timeoutInterval)
      }
    #else
      /// Test latency using specific `url` and `timeoutInterval`.
      ///
      /// This operation update `dnsLatency`, `routerLatency` and `internetLatency` after test finished.
      ///
      /// - Parameters:
      ///   - url: `URL` for internet latency tests.
      ///   - timeoutInterval: Time out interval for all latency tests.
      nonisolated public func testLatency(url: URL? = nil, timeoutInterval: Double = 5) async {
        await _testLatency(url: url, timeoutInterval: timeoutInterval)
      }
    #endif

    nonisolated private func _testLatency(url: URL? = nil, timeoutInterval: Double = 5) async {
      await withTaskGroup { g in
        g.addTask { [weak self] in
          guard let self else { return }
          let router = await airPort.networkService.v4.router
          guard let router, let address = IPv4Address(router) else { return }
          let routerLatency = await diagnostics.testRouterLatency(address: .ipv4(address))
          #if canImport(SwiftUI)
            let routerLatencyAttributed = attributedString(fromDuration: routerLatency)
          #endif
          await MainActor.run {
            self.routerLatency = routerLatency
            #if canImport(SwiftUI)
              self.routerLatencyAttributed = routerLatencyAttributed
            #endif
          }
        }

        g.addTask { [weak self] in
          guard let self else { return }
          let dnsLatency = await diagnostics.testDNSLatency(
            url: url, timeoutInterval: timeoutInterval)
          #if canImport(SwiftUI)
            let dnsLatencyAttributed = attributedString(fromDuration: dnsLatency)
          #endif
          await MainActor.run {
            self.dnsLatency = dnsLatency
            #if canImport(SwiftUI)
              self.dnsLatencyAttributed = dnsLatencyAttributed
            #endif
          }
        }

        g.addTask { [weak self] in
          guard let self else { return }
          let internetLatency = await diagnostics.testInternetLatency(
            url: url, timeoutInterval: timeoutInterval)
          #if canImport(SwiftUI)
            let internetLatencyAttributed = attributedString(fromDuration: internetLatency)
          #endif
          await MainActor.run { @MainActor in
            self.internetLatency = internetLatency
            #if canImport(SwiftUI)
              self.internetLatencyAttributed = internetLatencyAttributed
            #endif
          }
        }

        await g.waitForAll()
      }
    }
  }
#endif
