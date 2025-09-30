//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

/// A DataTransferReport contains performance information about data
/// transferred on an proxy tunnel connection for certain span of time. Multiple reports
/// can be retrieved from a single connection, starting and ending at different times.
/// This allows throughput to be measured based on how an application is using
/// a connection. A report may be created prior to a connection moving into
/// the .ready state, but measurements will not be collected until after the
/// connection is ready.
@available(SwiftStdlib 5.3, *)
public struct DataTransferReport: Codable, Hashable, Sendable {

  /// Length of time in duration over which the report collected
  /// information. This can be used to calculate throughput for
  /// application and transport bytes counts.
  @available(SwiftStdlib 5.7, *)
  public var duration: Duration {
    .seconds(_duration)
  }

  /// Length of time in seconds over which the report collected
  /// information. This can be used to calculate throughput for
  /// application and transport bytes counts.
  public var _duration: Double

  /// A path report contains counters and statistics observed
  /// by the connection along a single network path.
  public struct PathReport: Codable, Hashable, Sendable {

    /// The number of IP packets received.
    public let receivedIPPacketCount: UInt64

    /// The number of IP packets sent.
    public let sentIPPacketCount: UInt64

    /// The number of transport protocol bytes (such as TCP stream bytes) received.
    public let receivedTransportByteCount: UInt64

    /// The number of transport protocol bytes received as duplicates.
    public let receivedTransportDuplicateByteCount: UInt64

    /// The number of transport protocol bytes received out of order.
    public let receivedTransportOutOfOrderByteCount: UInt64

    /// The number of transport protocol bytes (such as TCP stream bytes) sent.
    public let sentTransportByteCount: UInt64

    /// The number of transport protocol bytes retransmitted as part of loss recovery.
    public let retransmittedTransportByteCount: UInt64

    /// The smoothed average of the transport protocol's round trip time, in seconds.
    public let transportSmoothedRTT: Double

    /// The minimum value of the transport protocol's round trip time, in seconds.
    public let transportMinimumRTT: Double

    /// The variance of the transport protocol's round trip time.
    public let transportRTTVariance: Double

    /// The number of bytes received by the application.
    public let receivedApplicationByteCount: UInt64

    /// The number of bytes sent by the application.
    public let sentApplicationByteCount: UInt64

    public init(
      receivedIPPacketCount: UInt64 = 0,
      sentIPPacketCount: UInt64 = 0,
      receivedTransportByteCount: UInt64 = 0,
      receivedTransportDuplicateByteCount: UInt64 = 0,
      receivedTransportOutOfOrderByteCount: UInt64 = 0,
      sentTransportByteCount: UInt64 = 0,
      retransmittedTransportByteCount: UInt64 = 0,
      transportSmoothedRTT: Double = 0,
      transportMinimumRTT: Double = 0,
      transportRTTVariance: Double = 0,
      receivedApplicationByteCount: UInt64 = 0,
      sentApplicationByteCount: UInt64 = 0
    ) {
      self.receivedIPPacketCount = receivedIPPacketCount
      self.sentIPPacketCount = sentIPPacketCount
      self.receivedTransportByteCount = receivedTransportByteCount
      self.receivedTransportDuplicateByteCount = receivedTransportDuplicateByteCount
      self.receivedTransportOutOfOrderByteCount = receivedTransportOutOfOrderByteCount
      self.sentTransportByteCount = sentTransportByteCount
      self.retransmittedTransportByteCount = retransmittedTransportByteCount
      self.transportSmoothedRTT = transportSmoothedRTT
      self.transportMinimumRTT = transportMinimumRTT
      self.transportRTTVariance = transportRTTVariance
      self.receivedApplicationByteCount = receivedApplicationByteCount
      self.sentApplicationByteCount = sentApplicationByteCount
    }
  }

  /// A report of path values that aggregates counters across
  /// the paths used, if there are multiple paths. If there is
  /// only one path, this will contains the values for that path.
  /// Values that can be summed are summed across paths. For values
  /// that cannot sum, the value of the primary path is used.
  public var aggregatePathReport: PathReport

  /// One or more reports for paths used by the connection.
  /// Connections that are not multipath capable will only
  /// generate one path report.
  public var pathReport: PathReport

  package init(
    duration: Double = 0,
    aggregatePathReport: PathReport = .init(),
    pathReport: PathReport = .init()
  ) {
    self._duration = duration
    self.aggregatePathReport = aggregatePathReport
    self.pathReport = pathReport
  }
}

#if swift(>=6.3) || canImport(Darwin)
  @available(SwiftStdlib 5.9, *)
  extension DataTransferReport {

    public typealias PersistentModel = V1._DataTransferReport

    public init(persistentModel: PersistentModel) {
      self._duration = persistentModel.duration.seconds
      self.aggregatePathReport = .init()
      self.pathReport = .init()
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension DataTransferReport.PathReport {

    public typealias PersistentModel = V1._PathReport

    public init(persistentModel: V1._PathReport) {
      self.receivedIPPacketCount = persistentModel.receivedIPPacketCount
      self.sentIPPacketCount = persistentModel.sentIPPacketCount
      self.receivedTransportByteCount = persistentModel.receivedTransportByteCount
      self.receivedTransportDuplicateByteCount = persistentModel.receivedTransportDuplicateByteCount
      self.receivedTransportOutOfOrderByteCount =
        persistentModel.receivedTransportOutOfOrderByteCount
      self.sentTransportByteCount = persistentModel.sentTransportByteCount
      self.retransmittedTransportByteCount = persistentModel.retransmittedTransportByteCount
      self.transportSmoothedRTT = persistentModel.transportSmoothedRTT
      self.transportMinimumRTT = persistentModel.transportMinimumRTT
      self.transportRTTVariance = persistentModel.transportRTTVariance
      self.receivedApplicationByteCount = persistentModel.receivedApplicationByteCount
      self.sentApplicationByteCount = persistentModel.sentApplicationByteCount
    }
  }
#endif

@available(SwiftStdlib 5.3, *)
extension DataTransferReport.PathReport {

  public static func &+ (lhs: DataTransferReport.PathReport, rhs: DataTransferReport.PathReport)
    -> DataTransferReport.PathReport
  {
    DataTransferReport.PathReport(
      receivedIPPacketCount: lhs.receivedIPPacketCount &+ rhs.receivedIPPacketCount,
      sentIPPacketCount: lhs.sentIPPacketCount &+ rhs.sentIPPacketCount,
      receivedTransportByteCount: lhs.receivedTransportByteCount &+ rhs.receivedTransportByteCount,
      receivedTransportDuplicateByteCount: lhs.receivedTransportDuplicateByteCount
        &+ rhs.receivedTransportDuplicateByteCount,
      receivedTransportOutOfOrderByteCount: lhs.receivedTransportOutOfOrderByteCount
        &+ rhs.receivedTransportOutOfOrderByteCount,
      sentTransportByteCount: lhs.sentTransportByteCount &+ rhs.sentTransportByteCount,
      retransmittedTransportByteCount: lhs.retransmittedTransportByteCount
        &+ rhs.retransmittedTransportByteCount,
      transportSmoothedRTT: rhs.transportSmoothedRTT,
      transportMinimumRTT: rhs.transportMinimumRTT,
      transportRTTVariance: rhs.transportRTTVariance,
      receivedApplicationByteCount: lhs.receivedApplicationByteCount
        &+ rhs.receivedApplicationByteCount,
      sentApplicationByteCount: lhs.sentApplicationByteCount &+ rhs.sentApplicationByteCount
    )
  }

  public static func &- (lhs: DataTransferReport.PathReport, rhs: DataTransferReport.PathReport)
    -> DataTransferReport.PathReport
  {
    DataTransferReport.PathReport(
      receivedIPPacketCount: lhs.receivedIPPacketCount &- rhs.receivedIPPacketCount,
      sentIPPacketCount: lhs.sentIPPacketCount &- rhs.sentIPPacketCount,
      receivedTransportByteCount: lhs.receivedTransportByteCount &- rhs.receivedTransportByteCount,
      receivedTransportDuplicateByteCount: lhs.receivedTransportDuplicateByteCount
        &- rhs.receivedTransportDuplicateByteCount,
      receivedTransportOutOfOrderByteCount: lhs.receivedTransportOutOfOrderByteCount
        &- rhs.receivedTransportOutOfOrderByteCount,
      sentTransportByteCount: lhs.sentTransportByteCount &- rhs.sentTransportByteCount,
      retransmittedTransportByteCount: lhs.retransmittedTransportByteCount
        &- rhs.retransmittedTransportByteCount,
      transportSmoothedRTT: rhs.transportSmoothedRTT,
      transportMinimumRTT: rhs.transportMinimumRTT,
      transportRTTVariance: rhs.transportRTTVariance,
      receivedApplicationByteCount: lhs.receivedApplicationByteCount
        &- rhs.receivedApplicationByteCount,
      sentApplicationByteCount: lhs.sentApplicationByteCount &- rhs.sentApplicationByteCount
    )
  }

  public static func &+= (
    lhs: inout DataTransferReport.PathReport, rhs: DataTransferReport.PathReport
  ) {
    lhs = lhs &+ rhs
  }

  public static func &-= (
    lhs: inout DataTransferReport.PathReport, rhs: DataTransferReport.PathReport
  ) {
    lhs = lhs &- rhs
  }
}
