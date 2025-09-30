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

import Atomics
import HTTPTypes
import NIOConcurrencyHelpers

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

// swift-format-ignore: AlwaysUseLowerCamelCase
@available(SwiftStdlib 5.3, *)
public let SQL_lastInsertedID = ManagedAtomic<UInt64>(0)

@available(SwiftStdlib 5.3, *)
@Lockable final public class Connection: Identifiable, Sendable {

  public var id: UInt64 {
    taskIdentifier
  }

  /// The identifier of the connection.
  public let taskIdentifier: UInt64

  /// The original request of the sesion.
  public var originalRequest: Request? {
    get { self._originalRequest.withLock { $0 } }
    set {
      self._originalRequest.withLock { $0 = newValue }
      if self.currentRequest == nil {
        self.currentRequest = newValue
      }
    }
  }
  private let _originalRequest: Mutex<Request?>

  /// The current request of the connection.
  @LockableTracked(accessLevel: .package)
  public var currentRequest: Request?

  @LockableTracked(accessLevel: .package)
  public var response: Response?

  public var earliestBeginDate: Date

  @available(SwiftStdlib 5.7, *)
  public var duration: Duration {
    .seconds(_duration)
  }

  public var _duration: Double

  public var taskDescription: String

  /// A bool value determine whether this sesion transport over TLS.
  public var tls: Bool

  /// Access the current state of the connection
  public var state: State

  @LockableTracked(accessLevel: .package)
  public var dnsResolutionReport: DNSResolutionReport?

  /// A establishment report.
  @LockableTracked(accessLevel: .package)
  public var establishmentReport: EstablishmentReport?

  public var forwardingReport: ForwardingReport?

  @LockableTracked(accessLevel: .package)
  public var dataTransferReport: DataTransferReport?

  public var processReport: ProcessReport?

  public init(
    taskIdentifier: UInt64 = SQL_lastInsertedID.loadThenWrappingIncrement(ordering: .relaxed)
  ) {
    self.taskIdentifier = taskIdentifier
    self._originalRequest = .init(nil)
    self._currentRequest = .init(nil)
    self._response = .init(nil)
    if #available(SwiftStdlib 5.5, *) {
      _earliestBeginDate = .init(.now)
    } else {
      _earliestBeginDate = .init(.init())
    }
    self.__duration = .init(0)
    self._taskDescription = .init("")
    self._tls = .init(false)
    self._state = .init(.establishing)
    self._dnsResolutionReport = .init(nil)
    self._establishmentReport = .init(nil)
    self._forwardingReport = .init(nil)
    self._dataTransferReport = .init(nil)
    self._processReport = .init(nil)
  }
}

@available(SwiftStdlib 5.3, *)
extension Connection: Codable {

  private enum CodingKeys: String, CodingKey {
    case taskIdentifier
    case originalRequest
    case currentRequest
    case response
    case earliestBeginDate
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

#if swift(>=6.3) || canImport(Darwin)
  @available(SwiftStdlib 5.9, *)
  extension Connection {

    public typealias PersistentModel = V1._Connection

    public convenience init(persistentModel: PersistentModel) {
      self.init(taskIdentifier: persistentModel.taskIdentifier)
      self.earliestBeginDate = persistentModel.earliestBeginDate
      self._duration = persistentModel.duration.seconds
      self.taskDescription = persistentModel.taskDescription
      self.tls = persistentModel.tls
      self.state = persistentModel.state
    }
  }
#endif
