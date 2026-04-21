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

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
  import SwiftData
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1 {

  #if canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA
    @Model
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
  #endif
  final public class _DNSResolutionReport {

    public var duration: Duration {
      .seconds(_duration)
    }

    /// The duration of the connection's establishment in seconds.
    /// This is the total time from when the successful connection
    /// attempt began until the connection becomes ready, including
    /// resolution, proxy evaluation, and protocol handshakes.
    public var _duration: Double

    /// A Resolution report represents one step of endpoint resolution.
    public struct Resolution: Codable, Hashable, Sendable {

      public typealias Source = EstablishmentReport.Resolution.Source

      /// The source of this resolution.
      public var source: Source

      /// The duration spent on this resolution step.
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

      public var endpoints: [Address]

      public init(
        source: Source,
        duration: TimeInterval,
        dnsProtocol: DNSProtocol,
        endpoints: [Address]
      ) {
        self.source = source
        self._duration = duration
        self.dnsProtocol = dnsProtocol
        self.endpoints = endpoints
      }
    }

    /// An array of zero or more Resolution reports, in order from first resolved
    /// to last resolved.
    public var resolutions: [Resolution]

    public var connection: _Connection?

    public init() {
      _duration = 0
      resolutions = []
    }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension V1._DNSResolutionReport {

  /// Merge new values from data transfer object.
  /// - Parameter data: New `DNSResolutionReport` to merge.
  public func mergeValues(_ data: DNSResolutionReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && NETBOT_REQUIRES_PERSISTENT_STORAGE_SWIFTDATA)
      self._duration = data._duration
      self.resolutions = data.resolutions.map {
        Resolution(
          source: $0.source,
          duration: $0._duration,
          dnsProtocol: $0.dnsProtocol,
          endpoints: $0.endpoints
        )
      }
    #else
      if self._duration != data._duration {
        self._duration = data._duration
      }
      let resolutions = data.resolutions.map {
        Resolution(
          source: $0.source,
          duration: $0._duration,
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
