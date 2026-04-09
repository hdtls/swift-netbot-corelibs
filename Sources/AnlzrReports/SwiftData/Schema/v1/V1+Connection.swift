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

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  import SwiftData
#endif

#if canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA
  @available(SwiftStdlib 5.9, *)
  extension V1 {

    @Model final public class _Connection {

      @available(SwiftStdlib 6.0, *)
      #Unique<_Connection>([\.taskIdentifier])

      @available(SwiftStdlib 6.0, *)
      #Index<_Connection>([\.taskIdentifier])

      /// The identifier of the connection.
      @Attribute(.unique)
      public var taskIdentifier: UInt64 = 0

      /// The persistent original request of the connection.
      public var originalRequest: _Request?

      /// The persistent current request of the connection.
      public var currentRequest: _Request?

      /// The persistent response of the connection.
      public var response: _Response?

      /// The date when the connection begin.
      public var earliestBeginDate = Date.now

      public var earliestBeginDateFormatted = ""

      public var duration: Duration {
        get { .seconds(_duration) }
        set { _duration = newValue.seconds }
      }
      public var _duration: Double = 0

      /// Description of the task.
      public var taskDescription = ""

      /// A boolean value determine whether the connection is transfer over TLS.
      public var tls = false

      public typealias State = Connection.State

      /// Access the current state of the connection
      public var state: State {
        get { State(rawValue: _state) ?? .establishing }
        set { _state = newValue.rawValue }
      }
      public var _state = State.establishing.rawValue

      /// The dns resolution report of the connection.
      @Relationship(deleteRule: .cascade, inverse: \_DNSResolutionReport.connection)
      public var dnsResolutionReport: _DNSResolutionReport?

      /// The persistent establishment report of the connection.
      @Relationship(deleteRule: .cascade, inverse: \_EstablishmentReport.connection)
      public var establishmentReport: _EstablishmentReport?

      /// A persistent forwardingReport report.
      @Relationship(deleteRule: .cascade, inverse: \_ForwardingReport.connection)
      public var forwardingReport: _ForwardingReport?

      /// The persistent process report of the connection.
      @Relationship(deleteRule: .cascade, inverse: \_ProcessReport.connection)
      public var processReport: _ProcessReport?

      @Relationship(deleteRule: .cascade, inverse: \_DataTransferReport.connection)
      public var dataTransferReport: _DataTransferReport?

      public init() {
        self.earliestBeginDateFormatted = self.earliestBeginDate
          .formatted(.dateTime.hour().minute().second())
      }
    }
  }
#else
  @available(SwiftStdlib 5.9, *)
  extension V1 {

    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    final public class _Connection {

      public var persistentModelID: UInt64 { taskIdentifier }

      /// The identifier of the connection.
      public var taskIdentifier: UInt64

      /// The persistent original request of the connection.
      public var originalRequest: _Request?

      /// The persistent current request of the connection.
      public var currentRequest: _Request?

      /// The persistent response of the connection.
      public var response: _Response?

      /// The date when the connection begin.
      public var earliestBeginDate = Date.now

      public var earliestBeginDateFormatted = ""

      public var duration = Duration.zero

      public var durationFormatted = "0ms"

      /// Description of the task.
      public var taskDescription = ""

      /// A boolean value determine whether the connection is transfer over TLS.
      public var tls = false

      public typealias State = Connection.State

      /// Access the current state of the connection
      public var state = State.establishing

      /// The dns resolution report of the connection.
      public var dnsResolutionReport: _DNSResolutionReport?

      /// The persistent establishment report of the connection.
      public var establishmentReport: _EstablishmentReport?

      /// A persistent forwardingReport report.
      public var forwardingReport: _ForwardingReport?

      /// The persistent process report of the connection.
      public var processReport: _ProcessReport?

      /// The persistent data transfer report of the connection.
      public var dataTransferReport: _DataTransferReport?

      public init() {
        self.taskIdentifier = 0
        self.earliestBeginDateFormatted = self.earliestBeginDate
          .formatted(.dateTime.hour().minute().second())
      }
    }
  }

  @available(SwiftStdlib 5.9, *)
  extension V1._Connection: Identifiable {
    public var id: UInt64 { persistentModelID }
  }
#endif

@available(SwiftStdlib 5.9, *)
extension V1._Connection {

  /// Merge new values from data transfer object.
  /// Please note that relationship values will not be merged.
  ///
  /// - Parameter data: New `Connection` to merge.
  public func mergeValues(_ data: Connection) {
    #if swift(>=6.2) && !(canImport(SwiftData) && ENABLE_EXPERIMENTAL_FEATURE_SWIFT_DATA)
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
