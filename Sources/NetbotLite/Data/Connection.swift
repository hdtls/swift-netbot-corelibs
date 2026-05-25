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

import HTTPTypes
import SynchronizationExtras

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if !canImport(Darwin) || !NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  import Synchronization
#endif

// swift-format-ignore: AlwaysUseLowerCamelCase
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public let SQL_lastInsertedID = Atomic<UInt64>(0)

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
@ObservationLockable final public class Connection: Identifiable, Sendable {

  public var id: UInt64 {
    taskIdentifier
  }

  /// The identifier of the connection.
  public let taskIdentifier: UInt64

  /// The original request of the sesion.
  public var originalRequest: Request? = nil

  /// The current request of the connection.
  @ObservationLockableTracked(accessLevel: .package)
  public var currentRequest: Request? = nil

  @ObservationLockableTracked(accessLevel: .package)
  public var response: Response? = nil

  public var earliestBeginDate: Date = .now

  public var duration: Duration = .zero

  public var taskDescription: String = ""

  /// A bool value determine whether this sesion transport over TLS.
  public var tls: Bool = false

  /// Access the current state of the connection
  public var state: State = .establishing

  @ObservationLockableTracked(accessLevel: .package)
  public var dnsResolutionReport: DNSResolutionReport? = nil

  /// A establishment report.
  @ObservationLockableTracked(accessLevel: .package)
  public var establishmentReport: EstablishmentReport? = nil

  public var forwardingReport: ForwardingReport? = nil

  @ObservationLockableTracked(accessLevel: .package)
  public var dataTransferReport: DataTransferReport? = nil

  public var processReport: ProcessReport? = nil

  public init(
    taskIdentifier: UInt64 = SQL_lastInsertedID.wrappingAdd(1, ordering: .relaxed).oldValue
  ) {
    self.taskIdentifier = taskIdentifier
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension Connection {

  public typealias Model = V1._Connection

  public convenience init(persistentModel: Model) {
    self.init(taskIdentifier: persistentModel.taskIdentifier)
    self.earliestBeginDate = persistentModel.earliestBeginDate
    self.duration = persistentModel.duration
    self.taskDescription = persistentModel.taskDescription
    self.tls = persistentModel.tls
    self.state = persistentModel.state
  }
}
