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
import NetbotDNS

/// Information about a DNS resolution attempt.
///
/// ``DNSResolutionReport`` describes the resolution
/// process used to discover endpoints for a connection, including timing
/// information and the individual resolution steps that were performed.
@available(SwiftStdlib 6.0, *)
public struct DNSResolutionReport: Codable, Hashable, Sendable {

  /// The date when the DNS resolution begin.
  public var earliestBeginDate: Date

  /// The duration of the connection's establishment in seconds.
  /// This is the total time from when the successful connection
  /// attempt began until the connection becomes ready, including
  /// resolution, proxy evaluation, and protocol handshakes.
  public var duration: Duration

  /// An array of zero or more Resolution reports, in order from first resolved
  /// to last resolved.
  public var resolutions: [Resolution]

  public struct Resolution: Codable, Hashable, Sendable {

    /// A Resolution.Source indicates if the set of endpoints was
    /// resolved locally using a cache or a query sent over the
    /// network.
    public typealias Source = DNSResolutionSource

    /// The source of this resolution.
    public var source: Source

    /// The length of time in seconds spent on this resolution step.
    public var duration: Duration

    /// The number of resolved endpoints discovered by the resolution step.
    public var endpointCount: Int { endpoints.count }

    /// A Resolution.DNSProtocol indicates the protocol used to resolve the endpoint,
    /// such as using UDP, TCP, TLS, or HTTPS for DNS.
    public typealias DNSProtocol = NetbotDNS.DNSProtocol

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

  package init(
    earliestBeginDate: Date,
    duration: Duration,
    resolutions: [Resolution]
  ) {
    self.earliestBeginDate = earliestBeginDate
    self.duration = duration
    self.resolutions = resolutions
  }
}

@available(SwiftStdlib 6.0, *)
extension DNSResolutionReport {

  /// In used persistent model typealias.
  public typealias Model = V1.DNSResolutionReport

  /// Create a new ``DNSResolutionReport`` from persistent dns resolution report.
  /// - Parameter persistentModel: Persistent dns resolution report.
  public init(persistentModel: Model) {
    self.earliestBeginDate = persistentModel.earliestBeginDate
    self.duration = persistentModel.duration
    self.resolutions = persistentModel.resolutions
  }
}
