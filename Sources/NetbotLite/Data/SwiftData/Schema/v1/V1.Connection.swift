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

#if canImport(FoundationEssentials)
  import FoundationEssentials
  import FoundationInternationalization
#else
  import Foundation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  @available(SwiftStdlib 6.0, *)
  extension V1 {

    /// A persistent representation of a network connection used for SwiftData storage.
    ///
    /// ``V1._Connection`` is the storage-layer counterpart of the in-memory
    /// ``Connection`` model. It mirrors the runtime properties of ``Connection``
    /// but is designed to be safely persisted using SwiftData.
    ///
    /// ## Design Purpose
    ///
    /// This type exists to:
    /// - Decouple runtime observation logic from persistence constraints
    /// - Provide a stable schema for SwiftData storage
    /// - Enable versioned migrations (V1, V2, ...)
    /// - Avoid storing transient or non-persistable runtime state directly
    ///
    /// ## Relationship to ``Connection``
    ///
    /// - ``Connection`` → runtime, observable, live network lifecycle model
    /// - ``V1._Connection`` → persisted snapshot of a connection
    ///
    /// Data is typically mapped bidirectionally:
    ///
    /// - ``Connection`` → ``V1._Connection`` when saving state
    /// - ``V1._Connection`` → ``Connection`` when restoring or querying history
    ///
    /// ## Versioning
    ///
    /// This model is part of ``V1`` schema and may evolve in future versions.
    /// New fields should be added via new schema versions (`V2._Connection`)
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
    /// - SeeAlso: ``Connection``.
    @Model final public class _Connection {

      #Unique<_Connection>([\.taskIdentifier])

      #Index<_Connection>([\.taskIdentifier])

      /// A unique identifier assigned to this connection task.
      ///
      /// This value is typically used to correlate logs, reports, and
      /// internal tracking for a single connection lifecycle.
      @Attribute(.unique)
      public var taskIdentifier: UInt64 = 0

      /// The original request that initiated this connection.
      ///
      /// This value is set once at the beginning of the connection lifecycle
      /// and typically remains unchanged even if `currentRequest` is modified.
      @Relationship(deleteRule: .cascade, inverse: \_Request.connection)
      public var originalRequest: _Request?

      /// The most recent request associated with this connection.
      ///
      /// This may change over time as redirects, rewrites, or proxy logic
      /// updates the active request being processed.
      @Relationship(deleteRule: .cascade, inverse: \_Request.connection)
      public var currentRequest: _Request?

      /// The response received for this connection, if available.
      ///
      /// This is typically set after the connection completes or when
      /// a partial response is received from upstream.
      @Relationship(deleteRule: .cascade, inverse: \_Response.connection)
      public var response: _Response?

      /// The earliest time at which this connection was initiated.
      ///
      /// Used for latency measurement and lifecycle tracking.
      public var earliestBeginDate = Date.now

      /// The formatted earliest time at which this connection was initiated.
      ///
      /// - SeeAlso: ``V1._Connection.earliestBeginDate``.
      public var earliestBeginDateFormatted = ""

      /// The total duration of the connection lifecycle.
      ///
      /// This value is typically updated when the connection finishes,
      /// representing total time spent from start to completion.
      @Attribute(.transformable(by: SQLValueTransformer<Duration>.self))
      public var duration: Duration = Duration.zero

      /// The formatted total duration of the connection lifecycle.
      ///
      /// - SeeAlso: ``duration``.
      public var durationFormatted = "0ms"

      /// A human-readable description of the connection task.
      ///
      /// This can include debugging context such as URL, host,
      /// routing decision, or internal pipeline stage.
      public var taskDescription = ""

      /// Indicates whether the connection is secured using TLS.
      ///
      /// When `true`, the connection is expected to be encrypted
      /// using TLS/SSL at the transport layer.
      public var tls = false

      /// A enum represents the progression of a `Connection` through stages.
      public typealias State = Connection.State

      /// The current lifecycle state of the connection.
      ///
      /// Represents the progression of the connection through stages
      /// such as establishing, active, completed, failed or cancelled.
      public var state: State {
        get { State(rawValue: _state) ?? .establishing }
        set { _state = newValue.rawValue }
      }

      /// The raw value of the current lifecycle state of the connection.
      ///
      /// This raw value property is used in `Predicate` of a query.
      ///
      /// - SeeAlso: ``state``.
      public var _state = State.establishing.rawValue

      /// DNS resolution report associated with this connection, if any.
      ///
      /// Contains information such as resolved addresses, lookup timing,
      /// and resolution results used for establishing the connection.
      @Relationship(deleteRule: .cascade, inverse: \_DNSResolutionReport.connection)
      public var dnsResolutionReport: _DNSResolutionReport?

      /// Report describing the connection establishment phase.
      ///
      /// Includes timing and metadata for TCP/TLS handshake or equivalent
      /// transport setup process.
      @Relationship(deleteRule: .cascade, inverse: \_EstablishmentReport.connection)
      public var establishmentReport: _EstablishmentReport?

      /// Report describing forwarding behavior.
      ///
      /// Captures routing decisions, proxy forwarding metadata,
      /// and intermediate transport details.
      @Relationship(deleteRule: .cascade, inverse: \_ForwardingReport.connection)
      public var forwardingReport: _ForwardingReport?

      /// Report describing the originating process of this connection.
      ///
      /// Useful for attribution, debugging, and per-process traffic analysis.
      @Relationship(deleteRule: .cascade, inverse: \_ProcessReport.connection)
      public var processReport: _ProcessReport?

      /// Report describing data transfer statistics and progress.
      ///
      /// Includes metrics such as bytes sent/received and transfer timing.
      @Relationship(deleteRule: .cascade, inverse: \_DataTransferReport.connection)
      public var dataTransferReport: _DataTransferReport?

      /// Create a new ``V1._Connection`` instance.
      public init() {
        self.earliestBeginDateFormatted = self.earliestBeginDate
          .formatted(.dateTime.hour().minute().second())
      }
    }
  }
#else
  @available(SwiftStdlib 6.0, *)
  extension V1 {

    /// A persistent representation of a network connection used for persistent storage.
    ///
    /// ``V1._Connection`` is the storage-layer counterpart of the in-memory
    /// ``Connection`` model. It mirrors the runtime properties of ``Connection``
    /// but is designed to be safely persisted using db.
    ///
    /// ## Design Purpose
    ///
    /// This type exists to:
    /// - Decouple runtime observation logic from persistence constraints
    /// - Provide a stable schema storage
    /// - Enable versioned migrations (V1, V2, ...)
    /// - Avoid storing transient or non-persistable runtime state directly
    ///
    /// ## Relationship to ``Connection``
    ///
    /// - ``Connection`` → runtime, observable, live network lifecycle model
    /// - ``V1._Connection`` → persisted snapshot of a connection
    ///
    /// Data is typically mapped bidirectionally:
    ///
    /// - ``Connection`` → ``V1._Connection`` when saving state
    /// - ``V1._Connection`` → ``Connection`` when restoring or querying history
    ///
    /// ## Versioning
    ///
    /// This model is part of ``V1`` schema and may evolve in future versions.
    /// New fields should be added via new schema versions (`V2._Connection`)
    /// to support safe migrations.
    ///
    /// - SeeAlso: ``Connection``.
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    final public class _Connection {

      public var persistentModelID: UInt64 { taskIdentifier }

      /// A unique identifier assigned to this connection task.
      ///
      /// This value is typically used to correlate logs, reports, and
      /// internal tracking for a single connection lifecycle.
      public var taskIdentifier: UInt64

      /// The original request that initiated this connection.
      ///
      /// This value is set once at the beginning of the connection lifecycle
      /// and typically remains unchanged even if `currentRequest` is modified.
      public var originalRequest: _Request?

      /// The most recent request associated with this connection.
      ///
      /// This may change over time as redirects, rewrites, or proxy logic
      /// updates the active request being processed.
      public var currentRequest: _Request?

      /// The response received for this connection, if available.
      ///
      /// This is typically set after the connection completes or when
      /// a partial response is received from upstream.
      public var response: _Response?

      /// The earliest time at which this connection was initiated.
      ///
      /// Used for latency measurement and lifecycle tracking.
      public var earliestBeginDate = Date.now

      /// The formatted earliest time at which this connection was initiated.
      ///
      /// - SeeAlso: ``V1._Connection.earliestBeginDate``.
      public var earliestBeginDateFormatted = ""

      /// The total duration of the connection lifecycle.
      ///
      /// This value is typically updated when the connection finishes,
      /// representing total time spent from start to completion.
      public var duration = Duration.zero

      /// The formatted total duration of the connection lifecycle.
      ///
      /// - SeeAlso: ``V1._Connection.duration``.
      public var durationFormatted = "0ms"

      /// A human-readable description of the connection task.
      ///
      /// This can include debugging context such as URL, host,
      /// routing decision, or internal pipeline stage.
      public var taskDescription = ""

      /// Indicates whether the connection is secured using TLS.
      ///
      /// When `true`, the connection is expected to be encrypted
      /// using TLS/SSL at the transport layer.
      public var tls = false

      /// A enum represents the progression of a `Connection` through stages.
      public typealias State = Connection.State

      /// The current lifecycle state of the connection.
      ///
      /// Represents the progression of the connection through stages
      /// such as establishing, active, completed, failed or cancelled.
      public var state = State.establishing

      /// DNS resolution report associated with this connection, if any.
      ///
      /// Contains information such as resolved addresses, lookup timing,
      /// and resolution results used for establishing the connection.
      public var dnsResolutionReport: _DNSResolutionReport?

      /// Report describing the connection establishment phase.
      ///
      /// Includes timing and metadata for TCP/TLS handshake or equivalent
      /// transport setup process.
      public var establishmentReport: _EstablishmentReport?

      /// Report describing forwarding behavior.
      ///
      /// Captures routing decisions, proxy forwarding metadata,
      /// and intermediate transport details.
      public var forwardingReport: _ForwardingReport?

      /// Report describing the originating process of this connection.
      ///
      /// Useful for attribution, debugging, and per-process traffic analysis.
      public var processReport: _ProcessReport?

      /// Report describing data transfer statistics and progress.
      ///
      /// Includes metrics such as bytes sent/received and transfer timing.
      public var dataTransferReport: _DataTransferReport?

      /// Creates a new ``V1._Connection`` instance.
      public init() {
        self.taskIdentifier = 0
        self.earliestBeginDateFormatted = self.earliestBeginDate
          .formatted(.dateTime.hour().minute().second())
      }
    }
  }

  @available(SwiftStdlib 6.0, *)
  extension V1._Connection: Identifiable {
    public var id: UInt64 { persistentModelID }
  }
#endif

@available(SwiftStdlib 6.0, *)
extension V1._Connection {

  /// Converts a runtime ``Connection`` into a persistent ``V1._Connection`` snapshot.
  ///
  /// This method captures the current state of the connection at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Important: Relationship values will not be merged.
  /// - Parameter data: New ``Connection`` to map.
  /// - SeeAlso: ``Connection.init(persistentModel:)``.
  public func mergeValues(_ data: Connection) {
    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      self.taskIdentifier = data.taskIdentifier
      if self.earliestBeginDate != data.earliestBeginDate {
        self.earliestBeginDateFormatted = data.earliestBeginDate
          .formatted(.dateTime.hour().minute().second())
      }
      self.earliestBeginDate = data.earliestBeginDate
      if self.duration != data.duration {
        self.durationFormatted = data.duration.formatted(
          .units(
            allowed: [.hours, .minutes, .seconds, .milliseconds],
            width: .narrow,
            maximumUnitCount: 3
          )
        )
      }
      self.duration = data.duration
      self.taskDescription = data.taskDescription
      self.tls = data.tls
      self.state = data.state
    #else
      if self.taskIdentifier != data.taskIdentifier {
        self.taskIdentifier = data.taskIdentifier
      }
      if self.earliestBeginDate != data.earliestBeginDate {
        self.earliestBeginDate = data.earliestBeginDate
        self.earliestBeginDateFormatted = data.earliestBeginDate
          .formatted(.dateTime.hour().minute().second())
      }
      if self.duration != data.duration {
        self.duration = data.duration
        self.durationFormatted = data.duration.formatted(
          .units(
            allowed: [.hours, .minutes, .seconds, .milliseconds],
            width: .narrow,
            maximumUnitCount: 3
          )
        )
      }
      if self.taskDescription != data.taskDescription {
        self.taskDescription = data.taskDescription
      }
      if self.tls != data.tls {
        self.tls = data.tls
      }
      if self.state != data.state {
        self.state = data.state
      }
    #endif
  }
}
