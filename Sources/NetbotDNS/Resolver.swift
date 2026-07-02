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

/// A protocol that covers an object that does DNS lookups.
@available(SwiftStdlib 6.0, *)
public protocol DNSResolver: Sendable {

  /// Lookup A records associated with `name`.
  func queryA(name: String) async throws -> ResolutionResult<ARecord>

  /// Lookup AAAA records associated with `name`.
  func queryAAAA(name: String) async throws -> ResolutionResult<AAAARecord>

  /// Lookup NS record associated with `name`.
  func queryNS(name: String) async throws -> ResolutionResult<NSRecord>

  /// Lookup CNAME record associated with `name`.
  func queryCNAME(name: String) async throws -> ResolutionResult<CNAMERecord>

  /// Lookup SOA record associated with `name`.
  func querySOA(name: String) async throws -> ResolutionResult<SOARecord>

  /// Lookup PTR record associated with `name`.
  func queryPTR(name: String) async throws -> ResolutionResult<PTRRecord>

  /// Lookup MX records associated with `name`.
  func queryMX(name: String) async throws -> ResolutionResult<MXRecord>

  /// Lookup TXT records associated with `name`.
  func queryTXT(name: String) async throws -> ResolutionResult<TXTRecord>

  /// Lookup SRV records associated with `name`.
  func querySRV(name: String) async throws -> ResolutionResult<SRVRecord>
}
