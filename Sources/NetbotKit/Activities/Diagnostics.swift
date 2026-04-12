//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

#if os(macOS)
  import Dispatch
  import Foundation
  import Logging
  import Network
  import Observation

  @available(SwiftStdlib 5.9, *)
  @MainActor @Observable public class Diagnostics {

    /// DNS latency in ms.
    public var dnsLatency = "N/Ams"

    /// Router latency in ms.
    public var routerLatency = "N/Ams"

    /// Internet latency in ms.
    public var internetLatency = "N/Ams"

    public let coreWLAN = WLANManager()

    private let formatStyle = Duration.UnitsFormatStyle.units(
      allowed: [.milliseconds],
      width: .narrow,
      maximumUnitCount: 1
    )
    private let logger = Logger(label: "com.tenbits.CoreWLAN.diagnostics")
    private let connectivity = Connectivity()

    nonisolated public init() {
    }

    /// Measure TCP connect time to port 53.
    private func measureRouterLatency() {
      guard let routerIPString = coreWLAN.networkService.v4.router,
        let router = IPv4Address(routerIPString)
      else {
        return
      }
      let connection = NWConnection(to: .hostPort(host: .ipv4(router), port: 53), using: .tcp)
      let startTime = Date.now
      connection.stateUpdateHandler = { state in
        switch state {
        case .ready:
          Task { @MainActor [weak self] in
            guard let self else { return }
            routerLatency = Duration.seconds(startTime.distance(to: .now)).formatted(formatStyle)
          }
        case .failed:
          connection.cancel()
        default: break
        }
      }
      connection.start(queue: .global())
    }

    /// Measure latency for Router, DNS and Internet.
    public func testLatency(connectivityCheckURL: URL? = nil, timeoutInterval: TimeInterval? = nil)
    {
      // Router latency test require router address.
      // To make router latency test available we try
      // to get router address as possible as we can.
      var retryAttampts = 3
      while retryAttampts > 0 {
        coreWLAN.getWLANInfo()
        if coreWLAN.networkService.v4.router != nil {
          break
        }
        retryAttampts -= 1
      }

      Task { @MainActor in
        do {
          let (dns, ttfb) = try await connectivity.measureInternetLatency(
            connectivityCheckURL: connectivityCheckURL,
            timeoutInterval: timeoutInterval
          )
          dnsLatency = dns.formatted(formatStyle)
          internetLatency = ttfb.formatted(formatStyle)
        } catch {
          internetLatency = "Failed"
        }
      }
      measureRouterLatency()
    }
  }
#endif
