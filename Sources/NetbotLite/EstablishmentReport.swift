// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2022 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NIOCore
import NetbotLiteData

#if canImport(Network)
  import Network
  import NIOTransportServices
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Channel {

  /// Asynchronously request the establishment report for this connection. If called
  /// prior to the connection being in the .ready state, the report will be initial one.
  ///
  /// - note: This method never failed and always produce an `EstablishmentReport`.
  func establishmentReport() -> EventLoopFuture<EstablishmentReport> {
    #if canImport(Network)
      let promise = eventLoop.makePromise(of: EstablishmentReport.self)
      getOption(NIOTSChannelOptions.establishmentReport).whenComplete {
        guard case .success(let f) = $0 else {
          promise.succeed(EstablishmentReport())
          return
        }
        f.whenComplete {
          guard case .success(let establishmentReport) = $0, let establishmentReport else {
            promise.succeed(EstablishmentReport())
            return
          }
          do {
            let establishmentReport = try EstablishmentReport(
              duration: establishmentReport.duration,
              attemptStartedAfterInterval: establishmentReport.attemptStartedAfterInterval,
              previousAttemptCount: establishmentReport.previousAttemptCount,
              sourceEndpoint: nil,
              usedProxy: establishmentReport.usedProxy,
              proxyEndpoint: establishmentReport.proxyEndpoint?.asAddress(),
              resolutions: establishmentReport.resolutions.map {
                var source = EstablishmentReport.Resolution.Source.query
                switch $0.source {
                case .query: break
                case .cache: source = .cache
                case .expiredCache: source = .expiredCache
                @unknown default:
                  break
                }

                var dnsProtocol = EstablishmentReport.Resolution.DNSProtocol.unknown
                switch $0.dnsProtocol {
                case .unknown: break
                case .udp: dnsProtocol = .udp
                case .tcp: dnsProtocol = .tcp
                case .tls: dnsProtocol = .tls
                case .https: dnsProtocol = .https
                @unknown default:
                  break
                }

                return try EstablishmentReport.Resolution(
                  source: source,
                  duration: $0.duration,
                  endpointCount: $0.endpointCount,
                  successfulEndpoint: $0.successfulEndpoint.asAddress(),
                  preferredEndpoint: $0.preferredEndpoint.asAddress(),
                  dnsProtocol: dnsProtocol
                )
              }
            )
            promise.succeed(establishmentReport)
          } catch {
            promise.fail(error)
          }
        }
      }
      return promise.futureResult
    #else
      return eventLoop.makeSucceededFuture(EstablishmentReport())
    #endif
  }
}
