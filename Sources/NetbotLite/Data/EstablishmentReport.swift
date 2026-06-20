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

/// Information about a connection establishment attempt.
///
/// ``EstablishmentReport`` describes how a connection was established,
/// including endpoint resolution, retry information, proxy usage,
/// and the time required to complete the attempt.
///
/// Use this type to analyze connection setup behavior and diagnose
/// connectivity issues.
@available(SwiftStdlib 6.0, *)
public struct EstablishmentReport: Codable, Hashable, Sendable {

  /// The duration of the connection's establishment in seconds.
  ///
  /// This is the total time from when the successful connection
  /// attempt began until the connection becomes ready, including
  /// resolution, proxy evaluation, and protocol handshakes.
  public var duration: Duration

  /// The delay after calling start() before the successful connection
  /// attempt began.
  ///
  /// For connections that succeed on the first attempt, this value will be 0.
  /// For connections that move into the .waiting state, this value will be
  /// greater than 0.
  public var attemptStartedAfterInterval: Double

  /// The number of connection attempts made before the successful attempt.
  ///
  /// A value of 0 indicates that this was the first attempt.
  public var previousAttemptCount: Int

  /// The local endpoint used to initiate the connection.
  public var sourceEndpoint: Address?

  /// The remote endpoint to which the connection was established.
  ///
  /// When a proxy is used, this value returns proxyEndpoint.
  /// Otherwise, it returns the first successfully resolved endpoint,
  /// if available.
  public var destinationEndpoint: Address? {
    guard usedProxy else {
      return resolutions.first?.successfulEndpoint
    }
    return proxyEndpoint
  }

  /// A Boolean value indicating whether a proxy was used.
  public var usedProxy: Bool

  /// The proxy endpoint used for the connection.
  ///
  /// This value is meaningful only when usedProxy is true.
  public var proxyEndpoint: Address?

  /// A Resolution report represents one step of endpoint resolution.
  public struct Resolution: Codable, Hashable, Sendable {

    /// A Resolution.Source indicates if the set of endpoints was
    /// resolved locally using a cache or a query sent over the
    /// network.
    ///
    /// - SeeAlso: ``DNSResolutionReport/Resolution/Source``
    public typealias Source = DNSResolutionReport.Resolution.Source

    /// The source of this resolution.
    public var source: Source

    /// The length of time in seconds spent on this resolution step.
    public var duration: Duration

    /// The number of resolved endpoints discovered by the resolution step.
    public var endpointCount: Int

    /// The resolved endpoint that led to a successful connection.
    public var successfulEndpoint: Address

    /// The first resolved endpoint attempted, which may be the same as the successfulEndpoint.
    public var preferredEndpoint: Address

    /// A Resolution.DNSProtocol indicates the protocol used to resolve the endpoint,
    /// such as using UDP, TCP, TLS, or HTTPS for DNS.
    ///
    /// - SeeAlso: ``DNSResolutionReport/Resolution/DNSProtocol``.
    public typealias DNSProtocol = DNSResolutionReport.Resolution.DNSProtocol

    /// The protocl of this DNS resolution.
    public var dnsProtocol: DNSProtocol

    /// Creates a ``EstablishmentReport/Resolution``.
    ///
    /// - Parameters:
    ///   - source: The source that produced the resolved endpoints.
    ///   - duration: The time spent performing the resolution step.
    ///   - endpointCount: The number of endpoints discovered during resolution.
    ///   - successfulEndpoint: The endpoint that ultimately resulted in a successful connection.
    ///   - preferredEndpoint: The first endpoint selected for connection attempts.
    ///   - dnsProtocol: The DNS protocol used during resolution.
    public init(
      source: Source,
      duration: Duration,
      endpointCount: Int,
      successfulEndpoint: Address,
      preferredEndpoint: Address,
      dnsProtocol: DNSProtocol
    ) {
      self.source = source
      self.duration = duration
      self.endpointCount = endpointCount
      self.successfulEndpoint = successfulEndpoint
      self.preferredEndpoint = preferredEndpoint
      self.dnsProtocol = dnsProtocol
    }
  }

  /// An array of zero or more Resolution reports, in order from first resolved
  /// to last resolved.
  ///
  /// Each resolution contains information about address lookup and
  /// endpoint selection that occurred before the connection succeeded
  /// or failed.
  public var resolutions: [Resolution]

  package init(
    duration: Duration,
    attemptStartedAfterInterval: Double,
    previousAttemptCount: Int,
    sourceEndpoint: Address?,
    usedProxy: Bool,
    proxyEndpoint: Address?,
    resolutions: [Resolution]
  ) {
    self.duration = duration
    self.attemptStartedAfterInterval = attemptStartedAfterInterval
    self.previousAttemptCount = previousAttemptCount
    self.sourceEndpoint = sourceEndpoint
    self.usedProxy = usedProxy
    self.proxyEndpoint = proxyEndpoint
    self.resolutions = resolutions
  }

  package init() {
    self.duration = .zero
    self.attemptStartedAfterInterval = 0
    self.previousAttemptCount = 0
    self.usedProxy = false
    self.resolutions = []
  }
}

@available(SwiftStdlib 6.0, *)
extension EstablishmentReport {

  /// In used persistent model typealias.
  public typealias Model = V1.EstablishmentReport

  /// Create a new ``EstablishmentReport`` from persistent establishment report.
  /// - Parameter persistentModel: Persistent establishment report.
  public init(persistentModel: Model) {
    duration = persistentModel.duration
    attemptStartedAfterInterval = persistentModel.attemptStartedAfterInterval
    previousAttemptCount = persistentModel.previousAttemptCount
    sourceEndpoint = persistentModel.sourceEndpoint
    usedProxy = persistentModel.usedProxy
    proxyEndpoint = persistentModel.proxyEndpoint
    resolutions = persistentModel.resolutions
  }
}
