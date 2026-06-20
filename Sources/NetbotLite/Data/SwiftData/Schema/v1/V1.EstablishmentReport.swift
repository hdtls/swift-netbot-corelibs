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

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import Foundation
  import SwiftData
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    /// Information about a connection establishment attempt.
    ///
    /// ``V1/EstablishmentReport-6l7ln`` describes how a connection was established,
    /// including endpoint resolution, retry information, proxy usage,
    /// and the time required to complete the attempt.
    ///
    /// Use this type to analyze connection setup behavior and diagnose
    /// connectivity issues.
    @Model final public class EstablishmentReport {

      /// The duration of the connection's establishment in seconds.
      ///
      /// This is the total time from when the successful connection
      /// attempt began until the connection becomes ready, including
      /// resolution, proxy evaluation, and protocol handshakes.
      @Attribute(.transformable(by: SQLValueTransformer<Duration>.self))
      public var duration: Duration = Duration.zero

      /// The delay after calling start() before the successful connection
      /// attempt began.
      ///
      /// For connections that succeed on the first attempt, this value will be 0.
      /// For connections that move into the .waiting state, this value will be
      /// greater than 0.
      public var attemptStartedAfterInterval: Double = 0

      /// The number of connection attempts made before the successful attempt.
      ///
      /// A value of 0 indicates that this was the first attempt.
      public var previousAttemptCount: Int = 0

      /// The local endpoint used to initiate the connection.
      @Attribute(.transformable(by: SQLValueTransformer<Address>.self))
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
      public var usedProxy: Bool = false

      /// The endpoint of the proxy used by a connection, if applicable.
      @Attribute(.transformable(by: SQLValueTransformer<Address>.self))
      public var proxyEndpoint: Address?

      /// A Resolution represents one step of endpoint resolution.
      ///
      /// - SeeAlso: ``EstablishmentReport/Resolution``.
      public typealias Resolution = NetbotLiteData.EstablishmentReport.Resolution

      /// An array of zero or more Resolution reports, in order from first resolved
      /// to last resolved.
      ///
      /// Each resolution contains information about address lookup and
      /// endpoint selection that occurred before the connection succeeded
      /// or failed.
      public var resolutions: [Resolution] = []

      /// The connection associated with the establishment attempt.
      public var connection: V1.Connection?

      /// Creates an empty ``V1/EstablishmentReport-6l7ln``.
      public init() {}
    }
  #else
    /// Information about a connection establishment attempt.
    ///
    /// ``V1/EstablishmentReport-6l7ln`` describes how a connection was established,
    /// including endpoint resolution, retry information, proxy usage,
    /// and the time required to complete the attempt.
    ///
    /// Use this type to analyze connection setup behavior and diagnose
    /// connectivity issues.
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    final public class EstablishmentReport {

      /// The duration of the connection's establishment in seconds.
      ///
      /// This is the total time from when the successful connection
      /// attempt began until the connection becomes ready, including
      /// resolution, proxy evaluation, and protocol handshakes.
      public var duration: Duration = Duration.zero

      /// The delay after calling start() before the successful connection
      /// attempt began.
      ///
      /// For connections that succeed on the first attempt, this value will be 0.
      /// For connections that move into the .waiting state, this value will be
      /// greater than 0.
      public var attemptStartedAfterInterval: Double = 0

      /// The number of connection attempts made before the successful attempt.
      ///
      /// A value of 0 indicates that this was the first attempt.
      public var previousAttemptCount: Int = 0

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
      public var usedProxy: Bool = false

      /// The proxy endpoint used for the connection.
      ///
      /// This value is meaningful only when usedProxy is true.
      public var proxyEndpoint: Address?

      /// A Resolution represents one step of endpoint resolution.
      ///
      /// - SeeAlso: ``EstablishmentReport/Resolution``.
      public typealias Resolution = NetbotLiteData.EstablishmentReport.Resolution

      /// An array of zero or more Resolution reports, in order from first resolved
      /// to last resolved.
      ///
      /// Each resolution contains information about address lookup and
      /// endpoint selection that occurred before the connection succeeded
      /// or failed.
      public var resolutions: [Resolution] = []

      /// The connection associated with the establishment attempt.
      public var connection: V1.Connection?

      /// Creates an empty ``V1/EstablishmentReport-6l7ln``.
      public init() {}
    }
  #endif
}

@available(SwiftStdlib 6.0, *)
extension V1.EstablishmentReport {

  /// Converts a runtime ``EstablishmentReport`` into a persistent
  /// ``V1/EstablishmentReport-6l7ln`` snapshot.
  ///
  /// This method captures the current state of the establishment activity at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Parameter data: New ``EstablishmentReport`` to map.
  public func mergeValues(_ data: NetbotLiteData.EstablishmentReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      self.duration = data.duration
      self.attemptStartedAfterInterval = data.attemptStartedAfterInterval
      self.previousAttemptCount = data.previousAttemptCount
      self.sourceEndpoint = data.sourceEndpoint
      self.usedProxy = data.usedProxy
      self.proxyEndpoint = data.proxyEndpoint
      self.resolutions = data.resolutions
    #else
      if self.duration != data.duration {
        self.duration = data.duration
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
      if self.resolutions != data.resolutions {
        self.resolutions = data.resolutions
      }
    #endif
  }
}
