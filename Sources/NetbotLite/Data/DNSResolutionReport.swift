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

import NEAddressProcessing

/// DNS resolution report.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct DNSResolutionReport: Codable, Hashable, Sendable {

  /// The duration of the connection's establishment in seconds.
  /// This is the total time from when the successful connection
  /// attempt began until the connection becomes ready, including
  /// resolution, proxy evaluation, and protocol handshakes.
  public var duration: Duration

  /// An array of zero or more Resolution reports, in order from first resolved
  /// to last resolved.
  public var resolutions: [Resolution]

  public struct Resolution: Codable, Hashable, Sendable {

    public typealias Source = EstablishmentReport.Resolution.Source

    /// The source of this resolution.
    public var source: Source

    /// The length of time in seconds spent on this resolution step.
    public var duration: Duration

    /// The number of resolved endpoints discovered by the resolution step.
    public var endpointCount: Int { endpoints.count }

    public typealias DNSProtocol = EstablishmentReport.Resolution.DNSProtocol

    /// The protocl of this DNS resolution.
    public var dnsProtocol: DNSProtocol

    /// The value of resolved endpoints discovered by the resolution step.
    public var endpoints: [Address]

    package init(source: Source, duration: Duration, dnsProtocol: DNSProtocol, endpoints: [Address])
    {
      self.source = source
      self.duration = duration
      self.dnsProtocol = dnsProtocol
      self.endpoints = endpoints
    }
  }

  package init(duration: Duration, resolutions: [Resolution]) {
    self.duration = duration
    self.resolutions = resolutions
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension DNSResolutionReport {

  public typealias Model = V1._DNSResolutionReport

  public init(persistentModel: Model) {
    self.duration = persistentModel.duration
    self.resolutions = persistentModel.resolutions.map {
      Resolution(
        source: $0.source,
        duration: $0.duration,
        dnsProtocol: $0.dnsProtocol,
        endpoints: $0.endpoints
      )
    }
  }
}
