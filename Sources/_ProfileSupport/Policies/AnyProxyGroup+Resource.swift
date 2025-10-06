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

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 5.3, *)
extension AnyProxyGroup {

  /// An object representing external proxies resource.
  public struct Resource: Codable, Hashable, Sendable {

    /// Resource source.
    public enum Source: UInt8, CaseIterable, Codable, Hashable, Sendable {
      /// The local resource was use.
      case cache

      /// A query was sent over the network, or perform file lookup.
      case query
    }

    /// The kind of resource interval or external.
    public var source = Source.cache

    /// URL for external policies.
    public var externalProxiesURL: URL?

    /// Auto update time interval for update external proxies provided by `externalProxiesURL`. Defaults to 1 day (86400 seconds).
    public var externalProxiesAutoUpdateTimeInterval = 86400

    /// Initialize an instance of `Resource` with specified `source` `externalProxiesURL` and `externalProxiesAutoUpdateTimeInterval`.
    public init(
      source: Source = Source.cache, externalProxiesURL: URL? = nil,
      externalProxiesAutoUpdateTimeInterval: Int = 86400
    ) {
      self.source = source
      self.externalProxiesURL = externalProxiesURL
      self.externalProxiesAutoUpdateTimeInterval = externalProxiesAutoUpdateTimeInterval
    }
  }
}
