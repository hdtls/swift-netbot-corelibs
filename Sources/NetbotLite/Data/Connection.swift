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

import Synchronization
import SynchronizationExtras

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

// swift-format-ignore: AlwaysUseLowerCamelCase
@available(SwiftStdlib 6.0, *)
public let SQL_lastInsertedID = Atomic<UInt64>(0)

/// A model representing a single network connection lifecycle.
///
/// `Connection` captures all observable metadata for a request/response
/// exchange as it moves through DNS resolution, connection establishment,
/// optional TLS negotiation, forwarding, and data transfer phases.
///
/// It is designed to be:
/// - **Observable**: properties are tracked using observation macros
/// - **Thread-safe**: conforms to `Sendable` with controlled mutation points
/// - **Traceable**: carries identifiers and reports for each pipeline stage
///
/// A `Connection` typically lives from the moment a request is created
/// until the response is fully received or the connection is terminated.
@available(SwiftStdlib 6.0, *)
@ObservationLockable @DebugDescription final public class Connection: Sendable {

  /// A unique identifier assigned to this connection task.
  ///
  /// This value is typically used to correlate logs, reports, and
  /// internal tracking for a single connection lifecycle.
  public let taskIdentifier: UInt64

  /// The original request that initiated this connection.
  ///
  /// This value is set once at the beginning of the connection lifecycle
  /// and typically remains unchanged even if `currentRequest` is modified.
  @ObservationLockableTracked(accessLevel: .package)
  public var originalRequest: Request? = nil

  /// The most recent request associated with this connection.
  ///
  /// This may change over time as redirects, rewrites, or proxy logic
  /// updates the active request being processed.
  @ObservationLockableTracked(accessLevel: .package)
  public var currentRequest: Request? = nil

  /// The response received for this connection, if available.
  ///
  /// This is typically set after the connection completes or when
  /// a partial response is received from upstream.
  @ObservationLockableTracked(accessLevel: .package)
  public var response: Response? = nil

  /// The earliest time at which this connection was initiated.
  ///
  /// Used for latency measurement and lifecycle tracking.
  public var earliestBeginDate: Date = .now

  /// The total duration of the connection lifecycle.
  ///
  /// This value is typically updated when the connection finishes,
  /// representing total time spent from start to completion.
  public var duration: Duration = .zero

  /// A human-readable description of the connection task.
  ///
  /// This can include debugging context such as URL, host,
  /// routing decision, or internal pipeline stage.
  public var taskDescription: String = ""

  /// Indicates whether the connection is secured using TLS.
  ///
  /// When `true`, the connection is expected to be encrypted
  /// using TLS/SSL at the transport layer.
  public var tls: Bool = false

  /// The current lifecycle state of the connection.
  ///
  /// Represents the progression of the connection through stages
  /// such as establishing, active, completed, failed or cancelled.
  @ObservationLockableTracked(accessLevel: .package)
  public var state: State = .establishing

  /// DNS resolution report associated with this connection, if any.
  ///
  /// Contains information such as resolved addresses, lookup timing,
  /// and resolution results used for establishing the connection.
  @ObservationLockableTracked(accessLevel: .package)
  public var dnsResolutionReport: DNSResolutionReport? = nil

  /// Report describing the connection establishment phase.
  ///
  /// Includes timing and metadata for TCP/TLS handshake or equivalent
  /// transport setup process.
  @ObservationLockableTracked(accessLevel: .package)
  public var establishmentReport: EstablishmentReport? = nil

  /// Report describing forwarding behavior.
  ///
  /// Captures routing decisions, proxy forwarding metadata,
  /// and intermediate transport details.
  @ObservationLockableTracked(accessLevel: .package)
  public var forwardingReport: ForwardingReport? = nil

  /// Report describing data transfer statistics and progress.
  ///
  /// Includes metrics such as bytes sent/received and transfer timing.
  @ObservationLockableTracked(accessLevel: .package)
  public var dataTransferReport: DataTransferReport? = nil

  /// Report describing the originating process of this connection.
  ///
  /// Useful for attribution, debugging, and per-process traffic analysis.
  @ObservationLockableTracked(accessLevel: .package)
  public var processReport: ProcessReport? = nil

  package var transportMetricsTask: Task<Void, Never>? = nil

  /// Creates a new `Connection` instance.
  ///
  /// - Parameter taskIdentifier: A unique identifier for the connection. If not provided,
  ///   a default identifier is generated using a monotonic counter.
  public init(
    taskIdentifier: UInt64 = SQL_lastInsertedID.wrappingAdd(1, ordering: .relaxed).oldValue
  ) {
    self.taskIdentifier = taskIdentifier
  }
}

@available(SwiftStdlib 6.0, *)
extension Connection: Identifiable {
  public var id: UInt64 {
    taskIdentifier
  }
}

@available(SwiftStdlib 6.0, *)
extension Connection: Equatable, Hashable {

  public static func == (lhs: Connection, rhs: Connection) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

@available(SwiftStdlib 6.0, *)
extension Connection: Codable {

  private enum CodingKeys: String, CodingKey {
    case taskIdentifier
    case originalRequest
    case currentRequest
    case response
    case earliestBeginDate
    case duration
    case taskDescription
    case tls
    case state
    case dnsResolutionReport
    case establishmentReport
    case forwardingReport
    case dataTransferReport
    case processReport
  }

  public convenience init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let taskIdentifier = try container.decode(UInt64.self, forKey: .taskIdentifier)
    self.init(taskIdentifier: taskIdentifier)
    self.originalRequest = try container.decodeIfPresent(Request.self, forKey: .originalRequest)
    self.currentRequest = try container.decodeIfPresent(Request.self, forKey: .currentRequest)
    self.response = try container.decodeIfPresent(Response.self, forKey: .response)
    self.earliestBeginDate = try container.decode(Date.self, forKey: .earliestBeginDate)
    self.duration = try container.decode(Duration.self, forKey: .duration)
    self.taskDescription = try container.decode(String.self, forKey: .taskDescription)
    self.tls = try container.decode(Bool.self, forKey: .tls)
    self.state = try container.decode(State.self, forKey: .state)
    self.dnsResolutionReport =
      try container
      .decodeIfPresent(DNSResolutionReport.self, forKey: .dnsResolutionReport)
    self.establishmentReport =
      try container
      .decodeIfPresent(EstablishmentReport.self, forKey: .establishmentReport)
    self.forwardingReport = try container.decodeIfPresent(
      ForwardingReport.self, forKey: .forwardingReport)
    self.dataTransferReport = try container.decodeIfPresent(
      DataTransferReport.self, forKey: .dataTransferReport)
    self.processReport = try container.decodeIfPresent(ProcessReport.self, forKey: .processReport)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(taskIdentifier, forKey: .taskIdentifier)
    try container.encodeIfPresent(originalRequest, forKey: .originalRequest)
    try container.encodeIfPresent(currentRequest, forKey: .currentRequest)
    try container.encodeIfPresent(response, forKey: .response)
    try container.encode(earliestBeginDate, forKey: .earliestBeginDate)
    try container.encode(duration, forKey: .duration)
    try container.encode(taskDescription, forKey: .taskDescription)
    try container.encode(tls, forKey: .tls)
    try container.encode(state, forKey: .state)
    try container.encodeIfPresent(dnsResolutionReport, forKey: .dnsResolutionReport)
    try container.encodeIfPresent(establishmentReport, forKey: .establishmentReport)
    try container.encodeIfPresent(forwardingReport, forKey: .forwardingReport)
    try container.encodeIfPresent(dataTransferReport, forKey: .dataTransferReport)
    try container.encodeIfPresent(processReport, forKey: .processReport)
  }
}

@available(SwiftStdlib 6.0, *)
extension Connection: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    """
    <\(String(describing: Connection.self)): \(ObjectIdentifier(self))> {
        taskIdentifier = \(taskIdentifier);
        originalRequest = \(String(describing: originalRequest));
        currentRequest = \(String(describing: currentRequest));
        response = \(String(describing: response));
        earliestBeginDate = \(earliestBeginDate);
        duration = \(duration);
        taskDescription = \(taskDescription);
        tls = \(tls);
        state = \(state);
        dnsResolutionReport = \(String(describing: dnsResolutionReport));
        establishmentReport = \(String(describing: establishmentReport));
        forwardingReport = \(String(describing: forwardingReport));
        dataTransferReport = \(String(describing: dataTransferReport));
        processReport = \(String(describing: processReport));
    }
    """
  }

  public var debugDescription: String {
    description
  }
}

@available(SwiftStdlib 6.0, *)
extension Connection {

  /// Persistent model class.
  public typealias Model = V1._Connection

  /// Create a new `Connection`instance.
  /// - Parameter persistentModel: A persistent model for the connection.
  public convenience init(persistentModel: Model) {
    self.init(taskIdentifier: persistentModel.taskIdentifier)
    self.earliestBeginDate = persistentModel.earliestBeginDate
    self.duration = persistentModel.duration
    self.taskDescription = persistentModel.taskDescription
    self.tls = persistentModel.tls
    self.state = persistentModel.state
  }
}
