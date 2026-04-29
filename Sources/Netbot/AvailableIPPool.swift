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

import Atomics
import NEAddressProcessing

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension IPv4Address {

  fileprivate var _address: UInt32 {
    rawValue.withUnsafeBytes {
      $0.load(as: UInt32.self)
    }
  }

  fileprivate init(_ desired: UInt32) {
    self.init(
      .init([
        UInt8((desired >> 24) & 0xFF),
        UInt8((desired >> 16) & 0xFF),
        UInt8((desired >> 8) & 0xFF),
        UInt8(desired & 0xFF),
      ]))!
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
public struct AvailableIPPool: Sendable {

  private let _storage: ManagedAtomic<UInt32>
  private let bounds: (lower: UInt32, upper: UInt32)

  public var lower: IPv4Address {
    IPv4Address(self.bounds.lower)
  }

  public var upper: IPv4Address {
    IPv4Address(self.bounds.upper)
  }

  /// Create a new IPv4 pool with specific IP range.
  ///
  /// - Important: IP addresses lowerBound and upperBound is used for caculate range and will not be generated
  public init(bounds: (lower: IPv4Address, upper: IPv4Address)) {
    self.bounds = (bounds.lower._address.bigEndian, bounds.upper._address.bigEndian)
    self._storage = .init(bounds.lower._address.bigEndian)
  }

  /// Create new IPv4 pool with specific block of IPv4 adresses.
  ///
  /// - Important: Network and broadcast address will not be generated.
  ///
  /// - Parameter desired: A block of IPv4 addresses string (e.g. 192.168.0.1/16).
  public init?(uncheckedBounds desired: String) {
    let components = desired.split(separator: "/")
    guard
      components.count == 2,
      case .ipv4(let address) = Address.Host(String(components[0])),
      let prefix = Int(components[1]),
      (0...UInt32.bitWidth).contains(prefix)
    else {
      return nil
    }

    let subnetmask = (UInt32(0xFFFF_FFFF) << (UInt32.bitWidth - prefix)).bigEndian
    let pointee = address.rawValue.withUnsafeBytes { $0.load(as: UInt32.self) }
    self.bounds = ((pointee & subnetmask).bigEndian, (pointee | ~subnetmask).bigEndian)
    // Skip network address.
    self._storage = .init(self.bounds.lower)
  }

  /// Generate the usable IP excluding network and broadcast addresses.
  public func loadThenWrappingIncrement() -> IPv4Address {
    var address = self._storage.loadThenWrappingIncrement(ordering: .relaxed)

    if address == self.bounds.lower {
      address = self._storage.loadThenWrappingIncrement(ordering: .relaxed)
    }

    // Broadcast address should be skipped.
    if address == self.bounds.upper {
      self._storage.store(self.bounds.lower &+ 1, ordering: .relaxed)
      address = self._storage.loadThenWrappingIncrement(ordering: .relaxed)
    }

    let finalize = IPv4Address(address)
    return finalize
  }

  func store(_ desired: IPv4Address) {
    self._storage.store(desired._address.bigEndian, ordering: .relaxed)
  }

  public func contains(_ address: IPv4Address) -> Bool {
    self.bounds.lower <= address._address.bigEndian
      && address._address.bigEndian <= self.bounds.upper
  }
}
