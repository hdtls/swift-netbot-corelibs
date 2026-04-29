// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ProtocolDNS {

  public enum MappingStrategy: Int, CaseIterable, Codable, Hashable, Sendable {
    /// Map resolved IP address.
    case mapping

    /// Map new domain name.
    case cname

    /// Map domain name resolution server.
    case dns
  }

  /// An object declaring DNS mapping.
  public struct Mapping: Equatable, Hashable, Sendable {

    /// The mapping strategy.
    public var strategy = MappingStrategy.mapping

    /// A boolean value determinse whether this mapping is enabled.
    public var isEnabled = true

    /// The domain to perform local DNS mapping.
    public var domainName = ""

    /// The mapped value.
    ///
    /// When the `kind` value is `mapping`, the value represents the mapped IP address.
    /// When the `kind` value is `cname`, the value represents the mapped new domain name.
    /// When the `kind` value is `dns`, the value represents the new domain name resolution server.
    public var value = ""

    /// The note on this DNS mapping.
    public var note = ""

    /// The date when the mapping created.
    public var creationDate: Date

    /// Initialize an instance of `ProtocolDNS.Mapping` object with specified `strategy`, `domainName`  `value`
    /// and `note`.
    public init(
      strategy: MappingStrategy = .mapping,
      domainName: String = "",
      value: String = "",
      note: String = ""
    ) {
      self.strategy = strategy
      self.domainName = domainName
      self.value = value
      self.creationDate = .now
    }
  }
}

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.9, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension ProtocolDNS.Mapping {

  public typealias Model = V1._ProtocolDNS._Mapping

  public init(persistentModel: Model) {
    self.init()
    isEnabled = persistentModel.isEnabled
    strategy = persistentModel.strategy
    domainName = persistentModel.domainName
    value = persistentModel.value
    note = persistentModel.note
    creationDate = persistentModel.creationDate
  }
}
