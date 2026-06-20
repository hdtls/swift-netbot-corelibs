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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin) || swift(>=6.3)
  import Observation
#endif

#if canImport(SwiftData) && SWTNE_REQUIRES_SQL
  import SwiftData
#endif

@available(SwiftStdlib 6.0, *)
extension V1 {

  #if canImport(SwiftData) && SWTNE_REQUIRES_SQL
    /// Information about how a connection was forwarded.
    ///
    /// ``V1/ForwardingReport-6wcc`` describes the forwarding
    /// mechanism used for a connection, including the forwarding protocol,
    /// matching rule, timing information, and the associated connection.
    @Model public class ForwardingReport {

      /// The earliest date and time at which forwarding began.
      ///
      /// This value identifies when forwarding activity was first observed
      /// for the connection.
      public var earliestBeginDate = Date.now

      /// The duration of the forwarding activity.
      ///
      /// This value represents the elapsed time during which the connection
      /// was forwarded.
      @Attribute(.transformable(by: SQLValueTransformer<Duration>.self))
      public var duration: Duration = Duration.zero

      /// The forwarding protocol used for the connection.
      ///
      /// Examples include direct forwarding and proxy-based forwarding.
      public var forwardProtocol = "DIRECT"

      /// The forwarding rule that matched the connection.
      ///
      /// This value may identify the rule, policy, or configuration entry
      /// responsible for selecting the forwarding behavior.
      public var forwardingRule: String?

      /// The connection associated with the forwarding activity.
      ///
      /// This value contains information about the network connection that
      /// was attributed to the forwarding activity.
      public var connection: V1.Connection?

      /// Creates an empty ``V1/ForwardingReport-6wcc``.
      public init() {}
    }
  #else
    /// Information about how a connection was forwarded.
    ///
    /// ``V1/ForwardingReport-6wcc`` describes the forwarding
    /// mechanism used for a connection, including the forwarding protocol,
    /// matching rule, timing information, and the associated connection.
    #if canImport(Darwin) || swift(>=6.3)
      @Observable
    #endif
    public class ForwardingReport {

      /// The earliest date and time at which forwarding began.
      ///
      /// This value identifies when forwarding activity was first observed
      /// for the connection.
      public var earliestBeginDate = Date.now

      /// The duration of the forwarding activity.
      ///
      /// This value represents the elapsed time during which the connection
      /// was forwarded.
      public var duration: Duration = Duration.zero

      /// The forwarding protocol used for the connection.
      ///
      /// Examples include direct forwarding and proxy-based forwarding.
      public var forwardProtocol = "DIRECT"

      /// The forwarding rule that matched the connection.
      ///
      /// This value may identify the rule, policy, or configuration entry
      /// responsible for selecting the forwarding behavior.
      public var forwardingRule: String?

      /// The connection associated with the forwarding activity.
      ///
      /// This value contains information about the network connection that
      /// was attributed to the forwarding activity.
      public var connection: V1.Connection?

      /// Creates an empty ``V1/ForwardingReport-6wcc``.
      public init() {}
    }
  #endif
}

@available(SwiftStdlib 6.0, *)
extension V1.ForwardingReport {

  /// Converts a runtime ``ForwardingReport`` into a persistent
  /// ``V1/ForwardingReport-6wcc`` snapshot.
  ///
  /// This method captures the current state of the forwarding activity at a point in time.
  /// Runtime-only fields (timers, live state transitions, observation locks)
  /// are flattened into persistable values.
  ///
  /// - Parameter data: New ``ForwardingReport`` to map.
  public func mergeValues(_ data: NetbotLiteData.ForwardingReport) {
    #if swift(>=6.2) && !(canImport(SwiftData) && SWTNE_REQUIRES_SQL)
      self.earliestBeginDate = data.earliestBeginDate
      self.duration = data.duration
      self.forwardingRule = data.forwardingRule
      self.forwardProtocol = data.forwardProtocol
    #else
      if self.earliestBeginDate != data.earliestBeginDate {
        self.earliestBeginDate = data.earliestBeginDate
      }
      if self.duration != data.duration {
        self.duration = data.duration
      }
      if self.forwardingRule != data.forwardingRule {
        self.forwardingRule = data.forwardingRule
      }
      if self.forwardProtocol != data.forwardProtocol {
        self.forwardProtocol = data.forwardProtocol
      }
    #endif
  }
}
