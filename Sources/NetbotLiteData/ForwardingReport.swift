// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

/// A ForwardingReport report represents forwarding rule matching.
#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct ForwardingReport: Codable, Hashable, Sendable {

  /// Length of time in seconds spent on forwarding rule matching.
  public var duration: Duration

  /// Forward protocol used to forward requests.
  public var forwardProtocol: String
  package var _forwardProtocol: (any Sendable)?

  /// Forwarding rule description for establishing connection.
  public var forwardingRule: String?
  package var _forwardingRule: (any Sendable)?

  package init(
    duration: Duration = .zero, forwardProtocol: String = "DIRECT", forwardingRule: String? = nil
  ) {
    self.duration = duration
    self.forwardProtocol = forwardProtocol
    self.forwardingRule = forwardingRule
  }

  public static func == (lhs: ForwardingReport, rhs: ForwardingReport) -> Bool {
    lhs.duration == rhs.duration && lhs.forwardProtocol == rhs.forwardProtocol
      && lhs.forwardingRule == rhs.forwardingRule
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(duration)
    hasher.combine(forwardProtocol)
    hasher.combine(forwardingRule)
  }

  private enum CodingKeys: CodingKey {
    case duration
    case forwardProtocol
    case forwardingRule
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.duration = try container.decode(Duration.self, forKey: .duration)
    self.forwardProtocol = try container.decode(String.self, forKey: .forwardProtocol)
    self.forwardingRule = try container.decodeIfPresent(String.self, forKey: .forwardingRule)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(duration, forKey: .duration)
    try container.encode(forwardProtocol, forKey: .forwardProtocol)
    try container.encodeIfPresent(forwardingRule, forKey: .forwardingRule)
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_9
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ForwardingReport {

  public typealias Model = V1._ForwardingReport

  public init(persistentModel: Model) {
    self.duration = persistentModel.duration
    self.forwardingRule = persistentModel.forwardingRule
    self.forwardProtocol = persistentModel.forwardProtocol
  }
}
