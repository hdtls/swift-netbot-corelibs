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

/// Information about how a connection was forwarded.
///
/// ``ForwardingReport`` describes the forwarding
/// mechanism used for a connection, including the forwarding protocol,
/// matching rule, timing information, and the associated connection.
@available(SwiftStdlib 6.0, *)
public struct ForwardingReport: Codable, Hashable, Sendable {

  /// The earliest date and time at which forwarding began.
  ///
  /// This value identifies when forwarding activity was first observed
  /// for the connection.
  public var earliestBeginDate: Date

  /// The duration of the forwarding activity.
  ///
  /// This value represents the elapsed time during which the connection
  /// was forwarded.
  public var duration: Duration

  /// The forwarding protocol used for the connection.
  ///
  /// Examples include direct forwarding and proxy-based forwarding.
  public var forwardProtocol: String
  package var _forwardProtocol: (any Sendable)?

  /// The forwarding rule that matched the connection.
  ///
  /// This value may identify the rule, policy, or configuration entry
  /// responsible for selecting the forwarding behavior.
  public var forwardingRule: String?
  package var _forwardingRule: (any Sendable)?

  package init(
    earliestBeginDate: Date,
    duration: Duration,
    forwardProtocol: String,
    forwardingRule: String?
  ) {
    self.earliestBeginDate = earliestBeginDate
    self.duration = duration
    self.forwardProtocol = forwardProtocol
    self.forwardingRule = forwardingRule
  }

  public static func == (lhs: ForwardingReport, rhs: ForwardingReport) -> Bool {
    lhs.earliestBeginDate == rhs.earliestBeginDate
      && lhs.duration == rhs.duration
      && lhs.forwardProtocol == rhs.forwardProtocol
      && lhs.forwardingRule == rhs.forwardingRule
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(earliestBeginDate)
    hasher.combine(duration)
    hasher.combine(forwardProtocol)
    hasher.combine(forwardingRule)
  }

  private enum CodingKeys: CodingKey {
    case earliestBeginDate
    case duration
    case forwardProtocol
    case forwardingRule
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.earliestBeginDate = try container.decode(Date.self, forKey: .earliestBeginDate)
    self.duration = try container.decode(Duration.self, forKey: .duration)
    self.forwardProtocol = try container.decode(String.self, forKey: .forwardProtocol)
    self.forwardingRule = try container.decodeIfPresent(String.self, forKey: .forwardingRule)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(earliestBeginDate, forKey: .earliestBeginDate)
    try container.encode(duration, forKey: .duration)
    try container.encode(forwardProtocol, forKey: .forwardProtocol)
    try container.encodeIfPresent(forwardingRule, forKey: .forwardingRule)
  }
}

@available(SwiftStdlib 6.0, *)
extension ForwardingReport {

  /// In used persistent model typealias.
  public typealias Model = V1.ForwardingReport

  /// Create a new ``ForwardingReport`` from persistent forwarding report.
  /// - Parameter persistentModel: Persistent forwarding report.
  public init(persistentModel: Model) {
    self.earliestBeginDate = persistentModel.earliestBeginDate
    self.duration = persistentModel.duration
    self.forwardingRule = persistentModel.forwardingRule
    self.forwardProtocol = persistentModel.forwardProtocol
  }
}
