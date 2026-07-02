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

import Dispatch
import NEAddressProcessing

@available(SwiftStdlib 6.0, *)
extension LocalDNSProxy: DNSResolver {

  public func queryA(name: String) async throws -> ResolutionResult<ARecord> {
    let startTime = ContinuousClock.now

    if let task = availableAQueries.value(forKey: name) {
      do {
        let expirables = try await task.value
        if !expirables.isEmpty {
          let records = expirables.map(\.record)
          return ResolutionResult(
            source: expirables.filter(\.isExpired).isEmpty ? .cache : .expiredCache,
            duration: startTime.duration(to: .now),
            dnsProtocol: .udp,
            records: records
          )
        }
      } catch {
        // If cached task result in failure, we should remove it from cache and start a fresh request.
        availableAQueries.removeValue(forKey: name)
      }
    }

    let records = try await queryA0(name: name).map(\.record)
    return ResolutionResult(
      source: .query,
      duration: startTime.duration(to: .now),
      dnsProtocol: .udp,
      records: records
    )
  }

  public func queryAAAA(name: String) async throws -> ResolutionResult<AAAARecord> {
    let startTime = ContinuousClock.now

    if let task = availableAAAAQueries.value(forKey: name) {
      do {
        let expirables = try await task.value
        if !expirables.isEmpty {
          let records = expirables.map(\.record)
          return ResolutionResult(
            source: expirables.filter(\.isExpired).isEmpty ? .cache : .expiredCache,
            duration: startTime.duration(to: .now),
            dnsProtocol: .udp,
            records: records
          )
        }
      } catch {
        // If cached task result in failure, we should remove it from cache and start a fresh request.
        availableAAAAQueries.removeValue(forKey: name)
      }
    }

    let records = try await queryAAAA0(name: name).map(\.record)
    return ResolutionResult(
      source: .query,
      duration: startTime.duration(to: .now),
      dnsProtocol: .udp,
      records: records
    )
  }

  private func queryA0(name: String) async throws -> [Expirable<ARecord>] {
    let task = Task<[Expirable<ARecord>], any Error>.detached {
      try await self.query(name: name, qt: .a).answerRRs.lazy.compactMap { $0 as? ARecord }.map {
        Expirable($0)
      }
    }
    availableAQueries.setValue(task, forKey: name)

    do {
      return try await task.value
    } catch {
      // If task failed we should remove it from cache.
      availableAQueries.removeValue(forKey: name)
      throw error
    }
  }

  private func queryAAAA0(name: String) async throws -> [Expirable<AAAARecord>] {
    let task = Task<[Expirable<AAAARecord>], any Error>.detached {
      try await self.query(name: name, qt: .aaaa).answerRRs.lazy.compactMap { $0 as? AAAARecord }
        .map {
          Expirable($0)
        }
    }
    availableAAAAQueries.setValue(task, forKey: name)

    do {
      return try await task.value
    } catch {
      // If task failed we should remove it from cache.
      availableAAAAQueries.removeValue(forKey: name)
      throw error
    }
  }

  public func queryNS(name: String) async throws -> ResolutionResult<NSRecord> {
    try await ResolutionResult(source: .query, dnsProtocol: .udp) {
      try await query(name: name, qt: .ns).answerRRs.compactMap { $0 as? NSRecord }
    }
  }

  public func queryCNAME(name: String) async throws -> ResolutionResult<CNAMERecord> {
    try await ResolutionResult(source: .query, dnsProtocol: .udp) {
      try await query(name: name, qt: .cname).answerRRs.compactMap { $0 as? CNAMERecord }
    }
  }

  public func querySOA(name: String) async throws -> ResolutionResult<SOARecord> {
    try await ResolutionResult(source: .query, dnsProtocol: .udp) {
      try await query(name: name, qt: .soa).answerRRs.compactMap { $0 as? SOARecord }
    }
  }

  public func queryPTR(name: String) async throws -> ResolutionResult<PTRRecord> {
    // Check to avoid query PTR records for disguised address.
    let v4 = ".in-addr.arpa"
    guard name.hasSuffix(v4) else {
      return try await ResolutionResult(source: .query, dnsProtocol: .udp) {
        try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
      }
    }
    let prefix = name[..<name.index(name.startIndex, offsetBy: name.count - v4.count)]
    let ipaddr = prefix.split(separator: ".").reversed().joined(separator: ".")
    guard let address = IPv4Address(ipaddr) else {
      return try await ResolutionResult(source: .query, dnsProtocol: .udp) {
        try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
      }
    }

    guard availableIPPool.contains(address) else {
      return try await ResolutionResult(source: .query, dnsProtocol: .udp) {
        try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
      }
    }
    guard let entry = disguisedARecords.first(where: { $0.1.record.data == address }) else {
      return await ResolutionResult(source: .query, dnsProtocol: .udp) { [] }

    }
    return await ResolutionResult(source: .cache, dnsProtocol: .udp) {
      [PTRRecord(domainName: name, ttl: entry.value.record.ttl, data: entry.key)]
    }
  }

  public func queryMX(name: String) async throws -> ResolutionResult<MXRecord> {
    try await ResolutionResult(source: .query, dnsProtocol: .udp) {
      try await query(name: name, qt: .mx).answerRRs.compactMap { $0 as? MXRecord }
    }
  }

  public func queryTXT(name: String) async throws -> ResolutionResult<TXTRecord> {
    try await ResolutionResult(source: .query, dnsProtocol: .udp) {
      try await query(name: name, qt: .txt).answerRRs.compactMap { $0 as? TXTRecord }
    }
  }

  public func querySRV(name: String) async throws -> ResolutionResult<SRVRecord> {
    try await ResolutionResult(source: .query, dnsProtocol: .udp) {
      try await query(name: name, qt: .srv).answerRRs.compactMap { $0 as? SRVRecord }
    }
  }
}

@available(SwiftStdlib 6.0, *)
extension LocalDNSProxy {
  struct Expirable<Record: ResourceRecord>: Sendable {

    var record: Record

    var time = DispatchTime.now()

    var isExpired: Bool {
      return time + Double(record.ttl) < .now()
    }

    init(_ record: Record) {
      self.record = record
    }
  }
}
