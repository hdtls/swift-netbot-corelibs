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

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
  import Foundation
  import SwiftData
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1 {

  #if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
    @Model final public class _EstablishmentReport {

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
      public var sourceEndpoint: Address? {
        get {
          guard let _sourceEndpoint else {
            return nil
          }
          return try? JSONDecoder().decode(Address.self, from: _sourceEndpoint)
        }
        set {
          guard let sourceEndpoint = newValue else {
            _sourceEndpoint = nil
            return
          }
          _sourceEndpoint = try? JSONEncoder().encode(sourceEndpoint)
        }
      }
      public var _sourceEndpoint: Data?

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
      public var proxyEndpoint: Address? {
        get {
          guard let _proxyEndpoint else {
            return nil
          }
          return try? JSONDecoder().decode(Address.self, from: _proxyEndpoint)
        }
        set {
          guard let proxyEndpoint = newValue else {
            _proxyEndpoint = nil
            return
          }
          _proxyEndpoint = try? JSONEncoder().encode(proxyEndpoint)
        }
      }
      public var _proxyEndpoint: Data?

      /// An array of zero or more Resolution reports, in order from first resolved
      /// to last resolved.
      public var resolutions: [Resolution]

      public var connection: _Connection?

      public init() {
        _duration = 0
        attemptStartedAfterInterval = 0
        previousAttemptCount = 0
        usedProxy = false
        resolutions = []
      }
    }
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    final public class _EstablishmentReport {

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

      /// An array of zero or more Resolution reports, in order from first resolved
      /// to last resolved.
      public var resolutions: [Resolution]

      public var connection: _Connection?

      public init() {
        _duration = 0
        attemptStartedAfterInterval = 0
        previousAttemptCount = 0
        usedProxy = false
        resolutions = []
      }
    }
  #endif
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._EstablishmentReport {

  /// A Resolution report represents one step of endpoint resolution.
  public struct Resolution: Codable, Hashable, Sendable {

    /// The source of this resolution.
    public var source: EstablishmentReport.Resolution.Source

    /// The duration spent on this resolution step.
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

    /// The protocl of this DNS resolution.
    public var dnsProtocol: EstablishmentReport.Resolution.DNSProtocol

    public init(
      source: EstablishmentReport.Resolution.Source,
      duration: TimeInterval,
      endpointCount: Int,
      successfulEndpoint: Address,
      preferredEndpoint: Address,
      dnsProtocol: EstablishmentReport.Resolution.DNSProtocol
    ) {
      self.source = source
      self._duration = duration
      self.endpointCount = endpointCount
      self.successfulEndpoint = successfulEndpoint
      self.preferredEndpoint = preferredEndpoint
      self.dnsProtocol = dnsProtocol
    }
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._EstablishmentReport {

  /// Merge new values from data transfer object.
  /// - Parameter data: New `EstablishmentRepor` to merge.
  public func mergeValues(_ data: EstablishmentReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA)
      self._duration = data._duration
      self.attemptStartedAfterInterval = data.attemptStartedAfterInterval
      self.previousAttemptCount = data.previousAttemptCount
      self.sourceEndpoint = data.sourceEndpoint
      self.usedProxy = data.usedProxy
      self.proxyEndpoint = data.proxyEndpoint
      self.resolutions = data.resolutions.map {
        Resolution(
          source: $0.source,
          duration: $0._duration,
          endpointCount: $0.endpointCount,
          successfulEndpoint: $0.successfulEndpoint,
          preferredEndpoint: $0.preferredEndpoint,
          dnsProtocol: $0.dnsProtocol
        )
      }
    #else
      if self._duration != data._duration {
        self._duration = data._duration
      }
      if self.attemptStartedAfterInterval != data.attemptStartedAfterInterval {
        self.attemptStartedAfterInterval = data.attemptStartedAfterInterval
      }
      if self.previousAttemptCount != data.previousAttemptCount {
        self.previousAttemptCount = data.previousAttemptCount
      }
      if self.sourceEndpoint != data.sourceEndpoint {
        self.sourceEndpoint = data.sourceEndpoint
      }
      if self.usedProxy != data.usedProxy {
        self.usedProxy = data.usedProxy
      }
      if self.proxyEndpoint != data.proxyEndpoint {
        self.proxyEndpoint = data.proxyEndpoint
      }
      let resolutions = data.resolutions.map {
        Resolution(
          source: $0.source,
          duration: $0._duration,
          endpointCount: $0.endpointCount,
          successfulEndpoint: $0.successfulEndpoint,
          preferredEndpoint: $0.preferredEndpoint,
          dnsProtocol: $0.dnsProtocol
        )
      }
      if self.resolutions != resolutions {
        self.resolutions = resolutions
      }
    #endif
  }
}
