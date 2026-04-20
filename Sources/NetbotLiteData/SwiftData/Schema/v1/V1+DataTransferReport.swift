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

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  import SwiftData
#endif

@available(SwiftStdlib 5.9, *)
extension V1 {

  #if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
    @Model public class _DataTransferReport {

      public var duration: Duration {
        .seconds(_duration)
      }

      /// Length of time in seconds over which the report collected
      /// information. This can be used to calculate throughput for
      /// application and transport bytes counts.
      public var _duration = Double.zero

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

      public var duration: Duration {
        .seconds(_duration)
      }

      /// Length of time in seconds over which the report collected
      /// information. This can be used to calculate throughput for
      /// application and transport bytes counts.
      public var _duration = Double.zero

      public var durationFormatted = "0ms"

      public typealias PathReport = V1._PathReport

      public var pathReport: PathReport?

      /// A report of path values that aggregates counters across
      /// the paths used, if there are multiple paths. If there is
      /// only one path, this will contains the values for that path.
      /// Values that can be summed are summed across paths. For values
      /// that cannot sum, the value of the primary path is used.
      public var aggregatePathReport: PathReport?

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

      public var pathReportFormatted = PathReportFormatted()

      public var aggregatePathReportFormatted = PathReportFormatted()

      public var connection: _Connection?

      public var program: _Program?

      public init() {}
    }
  #endif
}

@available(SwiftStdlib 5.9, *)
extension V1._DataTransferReport {

  /// Merge new values from data transfer object.
  /// - Parameter data: New `EstablishmentRepor` to merge.
  public func mergeValues(_ data: DataTransferReport) {
    if self._duration != data._duration {
      self.durationFormatted = data.duration.formatted(
        .units(
          allowed: [.hours, .minutes, .seconds, .milliseconds],
          width: .narrow,
          maximumUnitCount: 3
        )
      )
    }
    #if swift(>=6.2) && !(canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA)
      self._duration = data._duration
    #else
      if self._duration != data._duration {
        self._duration = data._duration
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
