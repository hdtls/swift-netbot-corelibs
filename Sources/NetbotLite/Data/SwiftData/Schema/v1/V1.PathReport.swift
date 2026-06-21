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

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData
#else
  import NetbotSQL
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  /// Statistics describing traffic observed on a network path.
  ///
  /// ``V1/PathReport`` contains packet counts, byte counts, retransmission
  /// statistics, round-trip time measurements, and application-level
  /// transfer metrics collected for a network path.
  ///
  /// Use this type to analyze network performance and data transfer
  /// characteristics for a connection.
  @Model public class PathReport {

    /// The number of IP packets received.
    public var receivedIPPacketCount: UInt64 = 0

    /// The number of IP packets sent.
    public var sentIPPacketCount: UInt64 = 0

    /// The number of transport-layer bytes received.
    ///
    /// For TCP connections, this value represents the number of bytes
    /// received by the transport protocol.
    public var receivedTransportByteCount: UInt64 = 0

    /// The number of duplicate transport-layer bytes received.
    ///
    /// Duplicate bytes may occur when packets are retransmitted and
    /// received more than once.
    public var receivedTransportDuplicateByteCount: UInt64 = 0

    /// The number of out-of-order transport-layer bytes received.
    ///
    /// These bytes arrived in a different order than originally sent.
    public var receivedTransportOutOfOrderByteCount: UInt64 = 0

    /// The number of transport-layer bytes sent.
    ///
    /// For TCP connections, this value represents the number of bytes
    /// transmitted by the transport protocol.
    public var sentTransportByteCount: UInt64 = 0

    /// The number of transport-layer bytes retransmitted.
    ///
    /// Retransmissions occur as part of packet loss recovery.
    public var retransmittedTransportByteCount: UInt64 = 0

    /// The smoothed round-trip time, in seconds.
    ///
    /// This value represents the transport protocol's calculated
    /// smoothed RTT.
    public var transportSmoothedRTT: Double = 0

    /// The minimum value of the transport protocol's round trip time, in seconds.
    public var transportMinimumRTT: Double = 0

    /// The variance of the transport protocol's round trip time.
    public var transportRTTVariance: Double = 0

    /// The number of bytes received by the application.
    public var receivedApplicationByteCount: UInt64 = 0

    /// The number of bytes sent by the application.
    public var sentApplicationByteCount: UInt64 = 0

    /// Human-readable representations of path report metrics.
    ///
    /// Use this type when displaying metrics in user interfaces.
    public struct Formatted: Codable, Hashable, Sendable {

      /// The formatted number of bytes received by the application.
      public var sentApplicationByteCount = "0 bytes"

      /// The formatted number of bytes sent by the application.
      public var receivedApplicationByteCount = "0 bytes"

      package init(
        sentApplicationByteCount: String = "0 bytes",
        receivedApplicationByteCount: String = "0 bytes"
      ) {
        self.sentApplicationByteCount = sentApplicationByteCount
        self.receivedApplicationByteCount = receivedApplicationByteCount
      }
    }

    /// Human-readable representations of the metrics.
    public var formatted: Formatted = Formatted()

    /// The data transfer report associated with this path report.
    ///
    /// This relationship identifies the report that owns the path metrics.
    public var dataTransferReport: V1.DataTransferReport?

    /// Creates an empty ``V1/PathReport``.
    public init() {}
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.PathReport {

  /// Converts a runtime ``DataTransferReport/PathReport`` into a persistent
  /// ``V1/PathReport`` snapshot.
  ///
  /// This method captures the current state of the path report at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Parameter data: New ``DataTransferReport/PathReport`` to map.
  public func mergeValues(_ data: NetbotLiteData.DataTransferReport.PathReport) {
    if self.sentApplicationByteCount != data.sentApplicationByteCount
      || self.receivedApplicationByteCount != data.receivedApplicationByteCount
    {
      self.formatted = .init(
        sentApplicationByteCount: data.sentApplicationByteCount
          .formatted(.byteCount(style: .binary, spellsOutZero: false)),
        receivedApplicationByteCount: data.receivedApplicationByteCount
          .formatted(.byteCount(style: .binary, spellsOutZero: false))
      )
    }

    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      self.receivedIPPacketCount = data.receivedIPPacketCount
      self.sentIPPacketCount = data.sentIPPacketCount
      self.receivedTransportByteCount = data.receivedTransportByteCount
      self.receivedTransportDuplicateByteCount = data.receivedTransportDuplicateByteCount
      self.receivedTransportOutOfOrderByteCount = data.receivedTransportOutOfOrderByteCount
      self.sentTransportByteCount = data.sentTransportByteCount
      self.retransmittedTransportByteCount = data.retransmittedTransportByteCount
      self.transportSmoothedRTT = data.transportSmoothedRTT
      self.transportMinimumRTT = data.transportMinimumRTT
      self.transportRTTVariance = data.transportRTTVariance
      self.receivedApplicationByteCount = data.receivedApplicationByteCount
      self.sentApplicationByteCount = data.sentApplicationByteCount
    #else
      if self.receivedIPPacketCount != data.receivedIPPacketCount {
        self.receivedIPPacketCount = data.receivedIPPacketCount
      }
      if self.sentIPPacketCount != data.sentIPPacketCount {
        self.sentIPPacketCount = data.sentIPPacketCount
      }
      if self.receivedTransportByteCount != data.receivedTransportByteCount {
        self.receivedTransportByteCount = data.receivedTransportByteCount
      }
      if self.receivedTransportDuplicateByteCount != data.receivedTransportDuplicateByteCount {
        self.receivedTransportDuplicateByteCount = data.receivedTransportDuplicateByteCount
      }
      if self.receivedTransportOutOfOrderByteCount != data.receivedTransportOutOfOrderByteCount {
        self.receivedTransportOutOfOrderByteCount = data.receivedTransportOutOfOrderByteCount
      }
      if self.sentTransportByteCount != data.sentTransportByteCount {
        self.sentTransportByteCount = data.sentTransportByteCount
      }
      if self.retransmittedTransportByteCount != data.retransmittedTransportByteCount {
        self.retransmittedTransportByteCount = data.retransmittedTransportByteCount
      }
      if self.transportSmoothedRTT != data.transportSmoothedRTT {
        self.transportSmoothedRTT = data.transportSmoothedRTT
      }
      if self.transportMinimumRTT != data.transportMinimumRTT {
        self.transportMinimumRTT = data.transportMinimumRTT
      }
      if self.transportRTTVariance != data.transportRTTVariance {
        self.transportRTTVariance = data.transportRTTVariance
      }
      if self.receivedApplicationByteCount != data.receivedApplicationByteCount {
        self.receivedApplicationByteCount = data.receivedApplicationByteCount
      }
      if self.sentApplicationByteCount != data.sentApplicationByteCount {
        self.sentApplicationByteCount = data.sentApplicationByteCount
      }
    #endif
  }
}
