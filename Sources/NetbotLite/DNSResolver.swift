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

import NetbotDNS

@available(SwiftStdlib 6.0, *)
struct DefaultDNSResolver: DNSResolver, Sendable {

  func queryA(name: String) async throws -> ResolutionResult<ARecord> {
    await ResolutionResult(source: .query, dnsProtocol: .udp) {
      []
    }
  }

  func queryAAAA(name: String) async throws -> ResolutionResult<AAAARecord> {
    await ResolutionResult(source: .query, dnsProtocol: .udp) {
      []
    }
  }

  func queryNS(name: String) async throws -> ResolutionResult<NSRecord> {
    await ResolutionResult(source: .query, dnsProtocol: .udp) {
      []
    }
  }

  func queryCNAME(name: String) async throws -> ResolutionResult<CNAMERecord> {
    await ResolutionResult(source: .query, dnsProtocol: .udp) {
      []
    }
  }

  func querySOA(name: String) async throws -> ResolutionResult<SOARecord> {
    await ResolutionResult(source: .query, dnsProtocol: .udp) {
      []
    }
  }

  func queryPTR(name: String) async throws -> ResolutionResult<PTRRecord> {
    await ResolutionResult(source: .query, dnsProtocol: .udp) {
      []
    }
  }

  func queryMX(name: String) async throws -> ResolutionResult<MXRecord> {
    await ResolutionResult(source: .query, dnsProtocol: .udp) {
      []
    }
  }

  func queryTXT(name: String) async throws -> ResolutionResult<TXTRecord> {
    await ResolutionResult(source: .query, dnsProtocol: .udp) {
      []
    }
  }

  func querySRV(name: String) async throws -> ResolutionResult<SRVRecord> {
    await ResolutionResult(source: .query, dnsProtocol: .udp) {
      []
    }
  }
}
