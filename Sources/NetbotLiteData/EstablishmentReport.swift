// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2024 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NEAddressProcessing

/// An EstablishmentReport contains information about how an proxy tunnel connection
/// became established. This is intended to be used for analysis of performance
/// after connection establishment. The report cannot be gathered until a
/// connection is in the .ready state.
#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct EstablishmentReport: Codable, Hashable, Sendable {

  /// The duration of the connection's establishment.
  /// This is the total time from when the successful connection
  /// attempt began until the connection becomes ready, including
  /// resolution, proxy evaluation, and protocol handshakes.
  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.7, *)
  #endif
  public var duration: Duration {
    .seconds(_duration)
  }

  /// The duration of the connection's establishment in seconds.
  /// This is the total time from when the successful connection
  /// attempt began until the connection becomes ready, including
  /// resolution, proxy evaluation, and protocol handshakes.
  public var _duration: Double

  /// The delay after calling start() before the successful connection
  /// attempt began. For connections that succeed on the first attempt,
  /// this value will be 0. For connections that move into the .waiting
  /// state, this value will be greater than 0.
  public var attemptStartedAfterInterval: Double

  /// The number of connection attempts made before the successful attempt.
  public var previousAttemptCount: Int

  /// The endpoint of the source.
  public var sourceEndpoint: Address?

  /// The endpoint of the remote.
  public var destinationEndpoint: Address? {
    guard usedProxy else {
      return resolutions.first?.successfulEndpoint
    }
    return proxyEndpoint
  }

  /// A boolean indicating if the connection was established through a proxy.
  public var usedProxy: Bool

  /// The endpoint of the proxy used by a connection, if applicable.
  public var proxyEndpoint: Address?

  /// A Resolution report represents one step of endpoint resolution.
  public struct Resolution: Codable, Hashable, Sendable {

    /// A Resolution.Source indicates if the set of endpoints was
    /// resolved locally using a cache or a query sent over the
    /// network.
    public enum Source: String, Codable, Hashable, Sendable {

      /// A query was sent over the network.
      case query

      /// The local cache was used.
      case cache

      /// An expired entry in the local cache was used.
      case expiredCache
    }

    /// The source of this resolution.
    public var source: Source

    /// The duration spent on this resolution step.
    #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
      @available(SwiftStdlib 5.7, *)
    #endif
    public var duration: Duration {
      .seconds(_duration)
    }

    /// The length of time in seconds spent on this resolution step.
    public var _duration: Double

    /// The number of resolved endpoints discovered by the resolution step.
    public var endpointCount: Int

    /// The resolved endpoint that led to a successful connection.
    public var successfulEndpoint: Address

    /// The first resolved endpoint attempted, which may be the same as the successfulEndpoint.
    public var preferredEndpoint: Address

    /// A Resolution.DNSProtocol indicates the protocol used to resolve the endpoint,
    /// such as using UDP, TCP, TLS, or HTTPS for DNS.
    public enum DNSProtocol: String, Codable, Hashable, Sendable {

      /// The protocol used is not known, or not applicable.
      case unknown

      /// Resolution used DNS over UDP.
      case udp

      /// Resolution used DNS over TCP.
      case tcp

      /// Resolution used DNS over TLS.
      case tls

      /// Resolution used DNS over HTTPS.
      case https
    }

    /// The protocl of this DNS resolution.
    public var dnsProtocol: DNSProtocol

    package init(
      source: Source,
      duration: TimeInterval,
      endpointCount: Int,
      successfulEndpoint: Address,
      preferredEndpoint: Address,
      dnsProtocol: DNSProtocol
    ) {
      self.source = source
      self._duration = duration
      self.endpointCount = endpointCount
      self.successfulEndpoint = successfulEndpoint
      self.preferredEndpoint = preferredEndpoint
      self.dnsProtocol = dnsProtocol
    }
  }

  /// An array of zero or more Resolution reports, in order from first resolved
  /// to last resolved.
  public var resolutions: [Resolution]

  package init(
    duration: Double,
    attemptStartedAfterInterval: Double,
    previousAttemptCount: Int,
    sourceEndpoint: Address?,
    usedProxy: Bool,
    proxyEndpoint: Address?,
    resolutions: [Resolution]
  ) {
    self._duration = duration
    self.attemptStartedAfterInterval = attemptStartedAfterInterval
    self.previousAttemptCount = previousAttemptCount
    self.sourceEndpoint = sourceEndpoint
    self.usedProxy = usedProxy
    self.proxyEndpoint = proxyEndpoint
    self.resolutions = resolutions
  }

  package init() {
    self._duration = 0
    self.attemptStartedAfterInterval = 0
    self.previousAttemptCount = 0
    self.usedProxy = false
    self.resolutions = []
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension EstablishmentReport {

  public typealias Model = V1._EstablishmentReport

  public init(persistentModel: Model) {
    _duration = persistentModel.duration.seconds
    attemptStartedAfterInterval = persistentModel.attemptStartedAfterInterval
    previousAttemptCount = persistentModel.previousAttemptCount
    sourceEndpoint = persistentModel.sourceEndpoint
    usedProxy = persistentModel.usedProxy
    proxyEndpoint = persistentModel.proxyEndpoint
    resolutions = persistentModel.resolutions.map {
      Resolution(
        source: $0.source, duration: $0.duration.seconds, endpointCount: $0.endpointCount,
        successfulEndpoint: $0.successfulEndpoint, preferredEndpoint: $0.preferredEndpoint,
        dnsProtocol: $0.dnsProtocol)
    }
  }
}
