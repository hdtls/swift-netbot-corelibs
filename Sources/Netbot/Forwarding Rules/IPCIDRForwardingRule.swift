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

import NEAddressProcessing
import NetbotDNS
import NetbotLite
import NetbotLiteData
import Synchronization

@available(SwiftStdlib 6.0, *)
struct IPCIDRForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  @usableFromInline final class _Storage {
    @usableFromInline var v4: AvailableIPPool?
    @usableFromInline var v6: AvailableIPv6Pool?
    @usableFromInline var uncheckedBounds: String
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible

    @inlinable init(uncheckedBounds: String, forwardProtocol: any ForwardProtocolConvertible) {
      self.v4 = .init(uncheckedBounds: uncheckedBounds)
      self.v6 = .init(uncheckedBounds: uncheckedBounds)
      self.uncheckedBounds = uncheckedBounds
      self.forwardProtocol = forwardProtocol
    }

    @inlinable func copy() -> _Storage {
      _Storage(uncheckedBounds: uncheckedBounds, forwardProtocol: forwardProtocol)
    }
  }

  @usableFromInline var _storage: _Storage

  @inlinable var forwardProtocol: any ForwardProtocolConvertible {
    get { _storage.forwardProtocol }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.forwardProtocol = newValue
    }
  }

  @inlinable var description: String {
    "IP-CIDR \(uncheckedBounds)"
  }

  /// IP CIDR string.
  @inlinable var uncheckedBounds: String {
    get { self._storage.uncheckedBounds }
    set {
      copyStorageIfNotUniquelyReferenced()
      self._storage.uncheckedBounds = newValue
      self._storage.v4 = .init(uncheckedBounds: newValue)
      self._storage.v6 = .init(uncheckedBounds: newValue)
    }
  }

  @inlinable init(
    uncheckedBounds: String,
    forwardProtocol: any ForwardProtocolConvertible
  ) {
    self._storage = _Storage(uncheckedBounds: uncheckedBounds, forwardProtocol: forwardProtocol)
  }

  #if swift(>=6.3)
    @inline(always)
  #else
    @inline(__always)
  #endif
  mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }

  @inlinable func predicate(_ connection: Connection) throws -> Bool {
    guard let address = connection.originalRequest?.address else { return false }

    func eval(_ address: Address) -> Bool {
      guard case .hostPort(let host, _) = address else { return false }

      switch host {
      case .ipv4(let address):
        return self._storage.v4?.contains(address) ?? false
      case .ipv6(let address):
        return self._storage.v6?.contains(address) ?? false
      default: return false
      }
    }

    guard !eval(address) else { return true }

    guard let resolutions = connection.dnsResolutionReport?.resolutions else { return false }

    return resolutions.flatMap { $0.endpoints }.contains { eval($0) }
  }
}

@available(SwiftStdlib 6.0, *)
extension IPCIDRForwardingRule._Storage: Hashable {
  static func == (lhs: IPCIDRForwardingRule._Storage, rhs: IPCIDRForwardingRule._Storage) -> Bool {
    lhs.uncheckedBounds == rhs.uncheckedBounds
      && lhs.forwardProtocol.asForwardProtocol().name
        == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(uncheckedBounds)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

@available(SwiftStdlib 6.0, *)
extension IPCIDRForwardingRule._Storage: @unchecked Sendable {}
