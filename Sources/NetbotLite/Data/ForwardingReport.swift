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

/// A ForwardingReport report represents forwarding rule matching.
@available(SwiftStdlib 6.0, *)
public struct ForwardingReport: Codable, Hashable, Sendable {

  /// The date when the forward lookup begin.
  public var earliestBeginDate: Date

  /// Length of time in seconds spent on forwarding rule matching.
  public var duration: Duration

  /// Forward protocol used to forward requests.
  public var forwardProtocol: String
  package var _forwardProtocol: (any Sendable)?

  /// Forwarding rule description for establishing connection.
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

  public typealias Model = V1._ForwardingReport

  public init(persistentModel: Model) {
    self.earliestBeginDate = persistentModel.earliestBeginDate
    self.duration = persistentModel.duration
    self.forwardingRule = persistentModel.forwardingRule
    self.forwardProtocol = persistentModel.forwardProtocol
  }
}
