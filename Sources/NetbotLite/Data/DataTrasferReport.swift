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

/// A DataTransferReport contains performance information about data
/// transferred on an proxy tunnel connection for certain span of time. Multiple reports
/// can be retrieved from a single connection, starting and ending at different times.
/// This allows throughput to be measured based on how an application is using
/// a connection. A report may be created prior to a connection moving into
/// the .ready state, but measurements will not be collected until after the
/// connection is ready.
@available(SwiftStdlib 6.0, *)
public struct DataTransferReport: Codable, Hashable, Sendable {

  /// Length of time in duration over which the report collected
  /// information. This can be used to calculate throughput for
  /// application and transport bytes counts.
  public var duration: Duration

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

    package init(
      receivedIPPacketCount: UInt64,
      sentIPPacketCount: UInt64,
      receivedTransportByteCount: UInt64,
      receivedTransportDuplicateByteCount: UInt64,
      receivedTransportOutOfOrderByteCount: UInt64,
      sentTransportByteCount: UInt64,
      retransmittedTransportByteCount: UInt64,
      transportSmoothedRTT: Double,
      transportMinimumRTT: Double,
      transportRTTVariance: Double,
      receivedApplicationByteCount: UInt64,
      sentApplicationByteCount: UInt64
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

    package init() {
      self.receivedIPPacketCount = 0
      self.sentIPPacketCount = 0
      self.receivedTransportByteCount = 0
      self.receivedTransportDuplicateByteCount = 0
      self.receivedTransportOutOfOrderByteCount = 0
      self.sentTransportByteCount = 0
      self.retransmittedTransportByteCount = 0
      self.transportSmoothedRTT = 0
      self.transportMinimumRTT = 0
      self.transportRTTVariance = 0
      self.receivedApplicationByteCount = 0
      self.sentApplicationByteCount = 0
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
    duration: Duration,
    aggregatePathReport: PathReport,
    pathReport: PathReport
  ) {
    self.duration = duration
    self.aggregatePathReport = aggregatePathReport
    self.pathReport = pathReport
  }

  package init() {
    self.duration = .zero
    self.aggregatePathReport = .init()
    self.pathReport = .init()
  }
}

@available(SwiftStdlib 6.0, *)
extension DataTransferReport {

  /// In used persistent model typealias.
  public typealias Model = V1.DataTransferReport

  /// Create a new ``DataTransferReport`` from persistent data transfer report.
  /// - Parameter persistentModel: Persistent data transfer report.
  public init(persistentModel: Model) {
    self.duration = persistentModel.duration
    self.aggregatePathReport = .init()
    self.pathReport = .init()
  }
}

@available(SwiftStdlib 6.0, *)
extension DataTransferReport.PathReport {

  /// In used persistent model typealias.
  public typealias Model = V1.PathReport

  /// Create a new ``DataTransferReport`` from persistent data transfer report.
  /// - Parameter persistentModel: Persistent data transfer report.
  public init(persistentModel: V1.PathReport) {
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

@available(SwiftStdlib 6.0, *)
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
