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

#if os(macOS)
  import Foundation
  import Logging
  import Observation
  #if canImport(SwiftUI)
    import SwiftUI
  #endif
  import Network

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
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

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.9, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  @MainActor @Observable final public class Activities {

    /// DNS latency.
    public var dnsLatency = Duration.zero
    #if canImport(SwiftUI)
      public var dnsLatencyAttributed: AttributedString = "N/Ams"
    #endif

    /// Router latency.
    public var routerLatency = Duration.zero
    #if canImport(SwiftUI)
      public var routerLatencyAttributed: AttributedString = "N/Ams"
    #endif

    /// Internet latency.
    public var internetLatency = Duration.zero
    #if canImport(SwiftUI)
      public var internetLatencyAttributed: AttributedString = "N/Ams"
    #endif

    public var events: [EventLog] = []

    public let coreWLAN = WLANManager()

    private let diagnostics = Diagnostics()

    private let formatStyle = Duration.UnitsFormatStyle.units(
      allowed: [.milliseconds],
      width: .narrow,
      maximumUnitCount: 1
    )

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
        let formatted = duration.formatted(formatStyle)
        var valuePart: String = "≤1"
        var unitPart: Substring = "ms"
        if let unitStartIndex = formatted.firstIndex(where: { !$0.isNumber }) {
          valuePart = formatted[..<unitStartIndex].trimmingCharacters(in: .whitespaces)
          if valuePart == "0" {
            valuePart = "≤1"
          }
          unitPart = formatted[unitStartIndex...]
        }

        var duration = AttributedString(valuePart)
        duration.font = .system(.title, weight: .bold)

        var unit = AttributedString(unitPart)
        unit.font = .system(.body, weight: .bold)

        return duration + unit
      }
    #endif

    #if swift(>=6.2)
      @concurrent public func testLatency(url: URL? = nil, timeoutInterval: Double = 5) async {
        await _testLatency(url: url, timeoutInterval: timeoutInterval)
      }
    #else
      nonisolated public func testLatency(url: URL? = nil, timeoutInterval: Double = 5) async {
        await _testLatency(url: url, timeoutInterval: timeoutInterval)
      }
    #endif

    nonisolated private func _testLatency(url: URL? = nil, timeoutInterval: Double = 5) async {
      await withTaskGroup { g in
        g.addTask { [weak self] in
          guard let self else { return }
          let router = await coreWLAN.networkService.v4.router
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
