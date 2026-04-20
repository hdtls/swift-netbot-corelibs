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

/// An Object declaring DNS mapping rules.
@available(SwiftStdlib 5.3, *)
public struct DNSMapping: Equatable, Hashable, Sendable {

  /// Kind of the mDNS apping.
  public enum Kind: Int, CaseIterable, Codable, Hashable, Sendable {
    /// Map resolved IP address.
    case mapping

    /// Map new domain name.
    case cname

    /// Map domain name resolution server.
    case dns
  }

  /// The kind of the mapping.
  public var kind = Kind.mapping

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

  /// Initialize an instance of `DNSMapping` object with specified `domainName`.
  public init(kind: Kind = .mapping, domainName: String = "", value: String = "", note: String = "")
  {
    self.domainName = domainName
    self.value = value
    if #available(SwiftStdlib 5.5, *) {
      self.creationDate = .now
    } else {
      self.creationDate = .init()
    }
  }
}

@available(SwiftStdlib 5.9, *)
extension DNSMapping {

  public typealias Model = V1._DNSMapping

  public init(persistentModel: Model) {
    self.init()
    isEnabled = persistentModel.isEnabled
    kind = persistentModel.kind
    domainName = persistentModel.domainName
    value = persistentModel.value
    note = persistentModel.note
    creationDate = persistentModel.creationDate
  }
}
