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
  import SwiftData
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    /// Information about a DNS resolution attempt.
    ///
    /// ``V1/DNSResolutionReport-psq7`` describes the resolution
    /// process used to discover endpoints for a connection, including timing
    /// information and the individual resolution steps that were performed.
    @Model final public class DNSResolutionReport {

      /// The date when the DNS resolution begin.
      public var earliestBeginDate = Date.now

      /// The duration of the connection's establishment in seconds.
      /// This is the total time from when the successful connection
      /// attempt began until the connection becomes ready, including
      /// resolution, proxy evaluation, and protocol handshakes.
      @Attribute(.transformable(by: SQLValueTransformer<Duration>.self))
      public var duration: Duration = Duration.zero

      /// A Resolution report represents one step of endpoint resolution.
      public typealias Resolution = NetbotLiteData.DNSResolutionReport.Resolution

      /// An array of zero or more Resolution reports, in order from first resolved
      /// to last resolved.
      public var resolutions: [Resolution] = []

      /// The connection associated with the DNS resolution attempt.
      public var connection: V1.Connection?

      /// Create an empty ``V1/DNSResolutionReport-psq7``.
      public init() {}
    }
  #else
    /// Information about a DNS resolution attempt.
    ///
    /// ``V1/DNSResolutionReport-psq7`` describes the resolution
    /// process used to discover endpoints for a connection, including timing
    /// information and the individual resolution steps that were performed.
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    final public class DNSResolutionReport {

      /// The date when the DNS resolution begin.
      public var earliestBeginDate = Date.now

      /// The duration of the connection's establishment in seconds.
      /// This is the total time from when the successful connection
      /// attempt began until the connection becomes ready, including
      /// resolution, proxy evaluation, and protocol handshakes.
      public var duration: Duration = Duration.zero

      /// A Resolution report represents one step of endpoint resolution.
      public typealias Resolution = NetbotLiteData.DNSResolutionReport.Resolution

      /// An array of zero or more Resolution reports, in order from first resolved
      /// to last resolved.
      public var resolutions: [Resolution] = []

      /// The connection associated with the DNS resolution attempt.
      public var connection: V1.Connection?

      /// Create an empty ``V1/DNSResolutionReport-psq7``.
      public init() {}
    }
  #endif
}

@available(SwiftStdlib 6.0, *)
extension V1.DNSResolutionReport {

  /// Converts a runtime ``DNSResolutionReport`` into a persistent
  /// ``V1/DNSResolutionReport-psq7`` snapshot.
  ///
  /// This method captures the current state of the DNS resolution activity at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Parameter data: New ``DNSResolutionReport`` to map.
  public func mergeValues(_ data: NetbotLiteData.DNSResolutionReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      self.earliestBeginDate = data.earliestBeginDate
      self.duration = data.duration
      self.resolutions = data.resolutions
    #else
      if self.earliestBeginDate != data.earliestBeginDate {
        self.earliestBeginDate = data.earliestBeginDate
      }
      if self.duration != data.duration {
        self.duration = data.duration
      }
      if self.resolutions != data.resolutions {
        self.resolutions = data.resolutions
      }
    #endif
  }
}
