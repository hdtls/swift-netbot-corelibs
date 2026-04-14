//===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2025 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 5.3, *)
public struct AnyForwardingRule: Equatable, Hashable, Sendable {

  /// The kind of the proxy rules.
  public enum Kind: String, Hashable, Codable, CaseIterable, Sendable {
    case domain = "DOMAIN"
    case domainKeyword = "DOMAIN-KEYWORD"
    case domainSuffix = "DOMAIN-SUFFIX"
    case domainset = "DOMAIN-SET"
    case ruleset = "RULE-SET"
    case geoip = "GEOIP"
    case ipcidr = "IP-CIDR"
    case processName = "PROCESS-NAME"
    case final = "FINAL"

    public var localizedName: String {
      switch self {
      case .domain:
        return "DOMAIN"
      case .domainKeyword:
        return "DOMAIN-KEYWORD"
      case .domainSuffix:
        return "DOMAIN-SUFFIX"
      case .domainset:
        return "DOMAIN-SET"
      case .ruleset:
        return "RULE-SET"
      case .geoip:
        return "GEOIP"
      case .ipcidr:
        return "IP-CIDR"
      case .processName:
        return "PROCESS-NAME"
      case .final:
        return "FINAL"
      }
    }
  }

  /// A boolean value determinse whether the forwardingRule is enabled.
  public var isEnabled: Bool = true

  /// The kind of the rule.
  public var kind = Kind.domain

  /// Match expressioin of the rule.
  public var value: String = ""

  /// Note of the the.
  public var comment: String = ""

  /// Foreign key for setup reference between AnyForwardingRule and AnyProxy or AnyProxyGroup.
  ///
  /// Link to builtin direct proxy by default.
  public var foreignKey: String = "DIRECT"

  /// ForwardingRule matched notification settings.
  public struct Notification: Codable, Hashable, Sendable {

    /// Notification message.
    public var message = ""

    /// A boolean value determine whether should deliver  notification.
    public var showNotification = false

    /// Notification deliver time interval sendonds.
    public var timeInterval = 300

    public init(message: String = "", showNotification: Bool = false, timeInterval: Int = 300) {
      self.message = message
      self.showNotification = showNotification
      self.timeInterval = timeInterval
    }
  }

  /// Notification settings.
  public var notification = Notification()

  /// Create instance of `AnyForwardingRule` with `kind`, `value` and `comment`.
  public init(kind: Kind = Kind.domain, value: String = "", comment: String = "") {
    self.kind = kind
    self.value = value
    self.comment = comment
  }
}

#if canImport(SwiftData)
  @available(SwiftStdlib 5.9, *)
  extension AnyForwardingRule {

    public typealias Model = V1._AnyForwardingRule

    public init(persistentModel: Model) {
      self.init()
      isEnabled = persistentModel.isEnabled
      kind = persistentModel.kind
      value = persistentModel.value
      comment = persistentModel.comment
      let lazyProxy = persistentModel.lazyProxy?.name
      let lazyProxyGroup = persistentModel.lazyProxyGroup?.name
      foreignKey = lazyProxy ?? lazyProxyGroup ?? "DIRECT"
      notification = persistentModel.notification
    }
  }
#endif
