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

/// A resolution source indicates if the set of endpoints was
/// resolved locally using a cache or a query sent over the
/// network.
public enum DNSResolutionSource: String, Codable, Hashable, Sendable {

  /// A query was sent over the network.
  case query

  /// The local cache was used.
  case cache

  /// An expired entry in the local cache was used.
  case expiredCache
}
