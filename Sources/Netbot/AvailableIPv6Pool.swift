// ===----------------------------------------------------------------------===//
//
// This source file is part of the Netbot open source project
//
// Copyright (c) 2026 Junfeng Zhang and the Netbot project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Netbot project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import NEAddressProcessing
import Synchronization

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

@available(SwiftStdlib 6.0, *)
extension IPv6Address {

  fileprivate var _address: UInt128 {
    rawValue.withUnsafeBytes {
      $0.load(as: UInt128.self)
    }
  }

  fileprivate init(_ desired: UInt128) {
    var desired = desired.bigEndian
    let rawValue = withUnsafeBytes(of: &desired) {
      Data($0)
    }
    self.init(rawValue)!
  }
}

@available(SwiftStdlib 6.0, *)
public struct AvailableIPv6Pool: ~Copyable {

  private let _storage: Atomic<UInt128>
  private let bounds: (lower: UInt128, upper: UInt128)

  public var lower: IPv6Address {
    IPv6Address(self.bounds.lower)
  }

  public var upper: IPv6Address {
    IPv6Address(self.bounds.upper)
  }

  /// Create a new IPv6 pool with specific IP range.
  ///
  /// - Important: IP addresses lowerBound and upperBound is used for caculate range and will not be generated
  public init(bounds: (lower: IPv6Address, upper: IPv6Address)) {
    self.bounds = (bounds.lower._address.bigEndian, bounds.upper._address.bigEndian)
    self._storage = .init(bounds.lower._address.bigEndian)
  }

  /// Create new IPv6 pool with specific block of IPv6 adresses.
  ///
  /// - Important: Network and broadcast address will not be generated.
  ///
  /// - Parameter desired: A block of IPv6 addresses string (e.g. 192.168.0.1/16).
  public init?(uncheckedBounds desired: String) {
    let components = desired.split(separator: "/")

    guard
      components.count == 2,
      case .ipv6(let address) = Address.Host(String(components[0])),
      let prefix = Int(components[1]),
      (0...UInt128.bitWidth).contains(prefix)
    else {
      return nil
    }

    let subnetmask = (UInt128.max << (UInt128.bitWidth - prefix)).bigEndian
    let pointee = address.rawValue.withUnsafeBytes { $0.load(as: UInt128.self) }
    self.bounds = ((pointee & subnetmask).bigEndian, (pointee | ~subnetmask).bigEndian)
    // Skip network address.
    self._storage = .init(bounds.lower)
  }

  /// Generate the usable IP excluding network and broadcast addresses.
  public func loadThenWrappingIncrement() -> IPv6Address {
    var desired: UInt128
    let (address, _) = self._storage.wrappingAdd(1, ordering: .relaxed)
    desired = address

    if address == self.bounds.lower {
      let (address, _) = self._storage.wrappingAdd(1, ordering: .relaxed)
      desired = address
    }

    // Broadcast address should be skipped.
    if address == self.bounds.upper {
      self._storage.store(self.bounds.lower &+ 1, ordering: .relaxed)
      let (address, _) = self._storage.wrappingAdd(1, ordering: .relaxed)
      desired = address
    }

    let finalize = IPv6Address(desired)
    return finalize
  }

  func store(_ desired: IPv6Address) {
    self._storage.store(desired._address.bigEndian, ordering: .relaxed)
  }

  public func contains(_ address: IPv6Address) -> Bool {
    self.bounds.lower <= address._address.bigEndian
      && address._address.bigEndian <= self.bounds.upper
  }
}

@available(SwiftStdlib 6.0, *)
extension AvailableIPv6Pool: Sendable {}
