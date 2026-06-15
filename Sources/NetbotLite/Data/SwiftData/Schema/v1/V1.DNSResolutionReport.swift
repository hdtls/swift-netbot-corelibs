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
    @Model final public class _DNSResolutionReport {

      /// The date when the DNS resolution begin.
      public var earliestBeginDate = Date.now

      /// The duration of the connection's establishment in seconds.
      /// This is the total time from when the successful connection
      /// attempt began until the connection becomes ready, including
      /// resolution, proxy evaluation, and protocol handshakes.
      @Attribute(.transformable(by: SQLValueTransformer<Duration>.self))
      public var duration: Duration = Duration.zero

      /// An array of zero or more Resolution reports, in order from first resolved
      /// to last resolved.
      public var resolutions: [Resolution] = []

      public var connection: _Connection?

      public init() {}
    }
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    final public class _DNSResolutionReport {

      /// The date when the DNS resolution begin.
      public var earliestBeginDate = Date.now

      /// The duration of the connection's establishment in seconds.
      /// This is the total time from when the successful connection
      /// attempt began until the connection becomes ready, including
      /// resolution, proxy evaluation, and protocol handshakes.
      public var duration: Duration = Duration.zero

      /// An array of zero or more Resolution reports, in order from first resolved
      /// to last resolved.
      public var resolutions: [Resolution] = []

      public var connection: _Connection?

      public init() {}
    }
  #endif
}

@available(SwiftStdlib 6.0, *)
extension V1._DNSResolutionReport {
  /// A Resolution report represents one step of endpoint resolution.
  public struct Resolution: Codable, Hashable, Sendable {

    public typealias Source = EstablishmentReport.Resolution.Source

    /// The source of this resolution.
    public var source: Source

    /// The duration spent on this resolution step.
    public var duration: Duration

    /// The number of resolved endpoints discovered by the resolution step.
    public var endpointCount: Int { endpoints.count }

    public typealias DNSProtocol = EstablishmentReport.Resolution.DNSProtocol

    /// The protocl of this DNS resolution.
    public var dnsProtocol: DNSProtocol

    public var endpoints: [Address]

    public init(
      source: Source,
      duration: Duration,
      dnsProtocol: DNSProtocol,
      endpoints: [Address]
    ) {
      self.source = source
      self.duration = duration
      self.dnsProtocol = dnsProtocol
      self.endpoints = endpoints
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension V1._DNSResolutionReport {

  /// Merge new values from DTO.
  /// - Parameter data: New `DNSResolutionReport` to merge.
  public func mergeValues(_ data: DNSResolutionReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      self.earliestBeginDate = data.earliestBeginDate
      self.duration = data.duration
      self.resolutions = data.resolutions.map {
        Resolution(
          source: $0.source,
          duration: $0.duration,
          dnsProtocol: $0.dnsProtocol,
          endpoints: $0.endpoints
        )
      }
    #else
      if self.earliestBeginDate != data.earliestBeginDate {
        self.earliestBeginDate = data.earliestBeginDate
      }
      if self.duration != data.duration {
        self.duration = data.duration
      }
      let resolutions = data.resolutions.map {
        Resolution(
          source: $0.source,
          duration: $0.duration,
          dnsProtocol: $0.dnsProtocol,
          endpoints: $0.endpoints
        )
      }
      if self.resolutions != resolutions {
        self.resolutions = resolutions
      }
    #endif
  }
}
