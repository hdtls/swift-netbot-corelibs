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

import NEAddressProcessing

/// DNS resolution report.
@available(SwiftStdlib 5.3, *)
public struct DNSResolutionReport: Codable, Hashable, Sendable {

  /// The duration of the connection's establishment.
  /// This is the total time from when the successful connection
  /// attempt began until the connection becomes ready, including
  /// resolution, proxy evaluation, and protocol handshakes.
  @available(SwiftStdlib 5.7, *)
  public var duration: Duration {
    .seconds(_duration)
  }

  /// The duration of the connection's establishment in seconds.
  /// This is the total time from when the successful connection
  /// attempt began until the connection becomes ready, including
  /// resolution, proxy evaluation, and protocol handshakes.
  public var _duration: Double

  /// An array of zero or more Resolution reports, in order from first resolved
  /// to last resolved.
  public var resolutions: [Resolution]

  public struct Resolution: Codable, Hashable, Sendable {

    public typealias Source = EstablishmentReport.Resolution.Source

    /// The source of this resolution.
    public var source: Source

    /// The duration spent on this resolution step.
    @available(SwiftStdlib 5.7, *)
    public var duration: Duration {
      .seconds(_duration)
    }

    /// The length of time in seconds spent on this resolution step.
    public var _duration: Double

    /// The number of resolved endpoints discovered by the resolution step.
    public var endpointCount: Int { endpoints.count }

    public typealias DNSProtocol = EstablishmentReport.Resolution.DNSProtocol

    /// The protocl of this DNS resolution.
    public var dnsProtocol: DNSProtocol

    /// The value of resolved endpoints discovered by the resolution step.
    public var endpoints: [Address]

    package init(source: Source, duration: Double, dnsProtocol: DNSProtocol, endpoints: [Address]) {
      self.source = source
      self._duration = duration
      self.dnsProtocol = dnsProtocol
      self.endpoints = endpoints
    }
  }

  package init(duration: Double, resolutions: [Resolution]) {
    self._duration = duration
    self.resolutions = resolutions
  }
}

@available(SwiftStdlib 5.9, *)
extension DNSResolutionReport {

  public typealias Model = V1._DNSResolutionReport

  public init(persistentModel: Model) {
    self._duration = persistentModel._duration
    self.resolutions = persistentModel.resolutions.map {
      Resolution(
        source: $0.source,
        duration: $0._duration,
        dnsProtocol: $0.dnsProtocol,
        endpoints: $0.endpoints
      )
    }
  }
}
