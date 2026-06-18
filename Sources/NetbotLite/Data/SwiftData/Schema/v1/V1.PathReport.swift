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
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  /// A path report contains counters and statistics observed
  /// by the connection along a single network path.
  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    @Model
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
  #endif
  public class _PathReport {

    /// The number of IP packets received.
    public var receivedIPPacketCount: UInt64 = 0

    /// The number of IP packets sent.
    public var sentIPPacketCount: UInt64 = 0

    /// The number of transport protocol bytes (such as TCP stream bytes) received.
    public var receivedTransportByteCount: UInt64 = 0

    /// The number of transport protocol bytes received as duplicates.
    public var receivedTransportDuplicateByteCount: UInt64 = 0

    /// The number of transport protocol bytes received out of order.
    public var receivedTransportOutOfOrderByteCount: UInt64 = 0

    /// The number of transport protocol bytes (such as TCP stream bytes) sent.
    public var sentTransportByteCount: UInt64 = 0

    /// The number of transport protocol bytes retransmitted as part of loss recovery.
    public var retransmittedTransportByteCount: UInt64 = 0

    /// The smoothed average of the transport protocol's round trip time, in seconds.
    public var transportSmoothedRTT: Double = 0

    /// The minimum value of the transport protocol's round trip time, in seconds.
    public var transportMinimumRTT: Double = 0

    /// The variance of the transport protocol's round trip time.
    public var transportRTTVariance: Double = 0

    /// The number of bytes received by the application.
    public var receivedApplicationByteCount: UInt64 = 0

    /// The number of bytes sent by the application.
    public var sentApplicationByteCount: UInt64 = 0

    /// Formatted path report including receivedApplicationByteCount and sentApplicationByteCout.
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

    /// Formatted path report.
    public var formatted: Formatted = Formatted()

    /// Data transfer report describe the relationship between ``V1._DataTransferReport`` and ``V1._PathReport``.
    public var dataTransferReport: _DataTransferReport?

    /// Create a new ``V1._PathReport`` instance.
    public init() {}
  }
}

@available(SwiftStdlib 6.0, *)
extension V1._PathReport {

  /// Converts a runtime ``DataTransferReport.PathReport`` into a persistent
  /// ``V1._PathReport`` snapshot.
  ///
  /// This method captures the current state of the path report at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Parameter data: New ``DataTransferReport.PathReport`` to map.
  /// - SeeAlso: ``DataTransferReport.PathReport.init(persistentModel:)``.
  public func mergeValues(_ data: DataTransferReport.PathReport) {
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
