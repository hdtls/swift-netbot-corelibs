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

import Dispatch
import NIOCore
import NetbotLite
import _DNSSupport

#if !canImport(Network)
  import NIOPosix
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension LocalDNSProxy: _DNSSupport.Resolver {

  public func queryA(name: String) async throws -> [ARecord] {
    guard let task = availableAQueries.value(forKey: name) else {
      return try await queryA0(name: name).map(\.record)
    }

    let expirables: [Expirable<ARecord>]
    do {
      expirables = try await task.value.filter { !$0.isExpired }
    } catch {
      // If cached task result in failure, we should remove it from cache and start a fresh request.
      availableAQueries.removeValue(forKey: name)
      expirables = []
    }
    guard expirables.isEmpty else {
      return expirables.map(\.record)
    }

    return try await queryA0(name: name).map(\.record)
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

  public func queryAAAA(name: String) async throws -> [AAAARecord] {
    guard let task = availableAAAAQueries.value(forKey: name) else {
      return try await self.queryAAAA0(name: name).map(\.record)
    }

    let expirables: [Expirable<AAAARecord>]
    do {
      expirables = try await task.value.filter { !$0.isExpired }
    } catch {
      // If cached task result in failure, we should remove it from cache and start a fresh request.
      availableAAAAQueries.removeValue(forKey: name)
      expirables = []
    }
    guard expirables.isEmpty else {
      return expirables.map { $0.record }
    }
    return try await self.queryAAAA0(name: name).map(\.record)
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

  public func queryNS(name: String) async throws -> [NSRecord] {
    try await query(name: name, qt: .ns).answerRRs.compactMap { $0 as? NSRecord }
  }

  public func queryCNAME(name: String) async throws -> [CNAMERecord] {
    try await query(name: name, qt: .cname).answerRRs.compactMap { $0 as? CNAMERecord }
  }

  public func querySOA(name: String) async throws -> [SOARecord] {
    try await query(name: name, qt: .soa).answerRRs.compactMap { $0 as? SOARecord }
  }

  public func queryPTR(name: String) async throws -> [PTRRecord] {
    // Check to avoid query PTR records for disguised address.
    let v4 = ".in-addr.arpa"
    guard name.hasSuffix(v4) else {
      return try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
    }
    let prefix = name[..<name.index(name.startIndex, offsetBy: name.count - v4.count)]
    let ipaddr = prefix.split(separator: ".").reversed().joined(separator: ".")
    guard let address = IPv4Address(ipaddr) else {
      return try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
    }

    guard availableIPPool.contains(address) else {
      return try await query(name: name, qt: .ptr).answerRRs.compactMap { $0 as? PTRRecord }
    }
    guard let entry = disguisedARecords.first(where: { $0.1.record.data == address }) else {
      return []
    }
    return [PTRRecord(domainName: name, ttl: entry.value.record.ttl, data: entry.key)]
  }

  public func queryMX(name: String) async throws -> [MXRecord] {
    try await query(name: name, qt: .mx).answerRRs.compactMap { $0 as? MXRecord }
  }

  public func queryTXT(name: String) async throws -> [TXTRecord] {
    try await query(name: name, qt: .txt).answerRRs.compactMap { $0 as? TXTRecord }
  }

  public func querySRV(name: String) async throws -> [SRVRecord] {
    try await query(name: name, qt: .srv).answerRRs.compactMap { $0 as? SRVRecord }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension LocalDNSProxy: NetbotLite.Resolver {

  public func initiateAQuery(host: String, port: Int) -> EventLoopFuture<[SocketAddress]> {
    group.next().makeFutureWithTask {
      try await self.queryA(name: host).map {
        try SocketAddress(ipAddress: "\($0.data)", port: port)
      }
    }
  }

  public func initiateAAAAQuery(host: String, port: Int) -> EventLoopFuture<[SocketAddress]> {
    group.next().makeFutureWithTask {
      try await self.queryAAAA(name: host).map {
        try SocketAddress(ipAddress: "\($0.data)", port: port)
      }
    }
  }

  public func cancelQueries() {}
}

#if !canImport(Network)
  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 5.3, *)
  #else
    @available(SwiftStdlib 6.0, *)
  #endif
  extension LocalDNSProxy: NIOPosix.Resolver {}
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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
