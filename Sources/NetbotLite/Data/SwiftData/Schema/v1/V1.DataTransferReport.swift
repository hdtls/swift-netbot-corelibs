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

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    @Model public class _DataTransferReport {

      /// Length of time over which the report collected
      /// information. This can be used to calculate throughput for
      /// application and transport bytes counts.
      @Attribute(.transformable(by: SQLValueTransformer<Duration>.self))
      public var duration: Duration = Duration.zero

      public var durationFormatted = "0ms"

      public typealias PathReport = V1._PathReport

      @Relationship(deleteRule: .cascade, inverse: \_PathReport.dataTransferReport)
      public var pathReport: PathReport?

      /// A report of path values that aggregates counters across
      /// the paths used, if there are multiple paths. If there is
      /// only one path, this will contains the values for that path.
      /// Values that can be summed are summed across paths. For values
      /// that cannot sum, the value of the primary path is used.
      @Relationship(deleteRule: .cascade, inverse: \_PathReport.dataTransferReport)
      public var aggregatePathReport: PathReport?

      public var pathReportFormatted = PathReportFormatted()

      public var aggregatePathReportFormatted = PathReportFormatted()

      public var connection: _Connection?

      public var program: _Program?

      public init() {}
    }
  #else
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    public class _DataTransferReport {

      /// Length of time over which the report collected
      /// information. This can be used to calculate throughput for
      /// application and transport bytes counts.
      public var duration = Duration.zero

      public var durationFormatted = "0ms"

      public typealias PathReport = V1._PathReport

      public var pathReport: PathReport?

      /// A report of path values that aggregates counters across
      /// the paths used, if there are multiple paths. If there is
      /// only one path, this will contains the values for that path.
      /// Values that can be summed are summed across paths. For values
      /// that cannot sum, the value of the primary path is used.
      public var aggregatePathReport: PathReport?

      public var pathReportFormatted = PathReportFormatted()

      public var aggregatePathReportFormatted = PathReportFormatted()

      public var connection: _Connection?

      public var program: _Program?

      public init() {}
    }
  #endif
}

@available(SwiftStdlib 6.0, *)
extension V1._DataTransferReport {
  public struct PathReportFormatted: Hashable, Sendable, Codable {
    public var sentApplicationByteCount = "0 bytes"
    public var receivedApplicationByteCount = "0 bytes"

    public init(
      sentApplicationByteCount: String = "0 bytes",
      receivedApplicationByteCount: String = "0 bytes"
    ) {
      self.sentApplicationByteCount = sentApplicationByteCount
      self.receivedApplicationByteCount = receivedApplicationByteCount
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension V1._DataTransferReport {

  /// Merge new values from DTO.
  /// - Parameter data: New `DataTransferReport` to merge.
  public func mergeValues(_ data: DataTransferReport) {
    if self.duration != data.duration {
      self.durationFormatted = data.duration.formatted(
        .units(
          allowed: [.hours, .minutes, .seconds, .milliseconds],
          width: .narrow,
          maximumUnitCount: 3
        )
      )
    }
    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      self.duration = data.duration
    #else
      if self.duration != data.duration {
        self.duration = data.duration
      }
    #endif

    if self.pathReport?.sentApplicationByteCount != data.pathReport.sentApplicationByteCount
      || self.pathReport?.receivedApplicationByteCount
        != data.pathReport.receivedApplicationByteCount
    {
      self.pathReportFormatted = .init(
        sentApplicationByteCount: data.pathReport.sentApplicationByteCount
          .formatted(.byteCount(style: .binary, spellsOutZero: false)),
        receivedApplicationByteCount: data.pathReport.receivedApplicationByteCount
          .formatted(.byteCount(style: .binary, spellsOutZero: false))
      )
    }

    if self.aggregatePathReport?.sentApplicationByteCount
      != data.aggregatePathReport.sentApplicationByteCount
      || self.aggregatePathReport?.receivedApplicationByteCount
        != data.aggregatePathReport.receivedApplicationByteCount
    {
      self.aggregatePathReportFormatted = .init(
        sentApplicationByteCount: data.aggregatePathReport.sentApplicationByteCount
          .formatted(.byteCount(style: .binary, spellsOutZero: false)),
        receivedApplicationByteCount: data.aggregatePathReport.receivedApplicationByteCount
          .formatted(.byteCount(style: .binary, spellsOutZero: false))
      )
    }
  }
}
