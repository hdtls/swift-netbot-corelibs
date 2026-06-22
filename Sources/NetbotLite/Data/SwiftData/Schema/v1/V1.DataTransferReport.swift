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

  /// A persistent representation of a data transfer performance information about
  /// data transferred on an proxy tunnel connection for certain span of time. used
  /// for SwiftData storage.
  ///
  /// ``V1/DataTransferReport`` is the storage-layer counterpart of the
  /// in-memory ``DataTransferReport`` model. It mirrors the runtime
  /// properties of `DataTransferReport` but is designed to be safely
  /// persisted using SwiftData.
  ///
  /// Multiple reports can be retrieved from a single connection, starting and ending
  /// at different times. This allows throughput to be measured based on how an
  /// application is using a connection. A report may be created prior to a connection
  /// moving into the .ready state, but measurements will not be collected until after
  /// the connection is ready.
  ///
  /// ## Design Purpose
  ///
  /// This type exists to:
  /// - Provide a stable schema for SwiftData storage
  /// - Enable versioned migrations (V1, V2, ...)
  /// - Avoid storing transient or non-persistable runtime state directly
  ///
  /// ## Versioning
  ///
  /// This model is part of ``V1`` schema and may evolve in future versions.
  /// New fields should be added via new schema versions (`V2.DataTransferReport`)
  /// to support safe migrations.
  ///
  /// ## SwiftData Constraints
  ///
  /// All properties in this model must conform to SwiftData storage rules:
  /// - Value types or relationships only
  /// - No transient computed-only fields unless marked non-persisted
  ///
  /// ## Usage
  ///
  /// This model is not intended for direct business logic usage.
  /// It should be accessed via SwiftData `ModelContext` queries or
  /// through mapping utilities.
  ///
  /// - SeeAlso: ``DataTransferReport``.
  @Model public class DataTransferReport {

    /// Length of time over which the report collected
    /// information. This can be used to calculate throughput for
    /// application and transport bytes counts.
    @Attribute(.transformable(by: SQLValueTransformer<Duration>.self))
    public var duration: Duration = Duration.zero

    /// Formatted length of time over which the report collected
    /// information.
    public var durationFormatted = "0ms"

    /// A report of path value in past one second.
    @Relationship(deleteRule: .cascade, inverse: \V1.PathReport.dataTransferReport)
    public var pathReport: V1.PathReport?

    /// A report of path values that aggregates counters across
    /// the paths used, if there are multiple paths. If there is
    /// only one path, this will contains the values for that path.
    /// Values that can be summed are summed across paths. For values
    /// that cannot sum, the value of the primary path is used.
    @Relationship(deleteRule: .cascade, inverse: \V1.PathReport.dataTransferReport)
    public var aggregatePathReport: V1.PathReport?

    /// Connection describe the relationship between ``V1/Connection`` and ``V1/DataTransferReport``.
    public var connection: V1.Connection?

    /// Program describe the relationship between ``V1/Program`` and ``V1/DataTransferReport``.
    public var program: V1.Program?

    /// Create a new ``V1/DataTransferReport`` instance.
    public init() {}
  }
}

@available(SwiftStdlib 6.0, *)
extension V1.DataTransferReport {

  /// Converts a runtime ``DataTransferReport`` into a persistent ``V1/DataTransferReport`` snapshot.
  ///
  /// This method captures the current state of the data transfer report at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Parameter data: New ``DataTransferReport`` to map.
  public func mergeValues(_ data: NetbotLiteData.DataTransferReport) {
    if self.duration != data.duration {
      self.durationFormatted = data.duration.formatted(
        .units(
          allowed: [.hours, .minutes, .seconds, .milliseconds],
          width: .narrow,
          maximumUnitCount: 3
        )
      )

      self.duration = data.duration
    }
  }
}
