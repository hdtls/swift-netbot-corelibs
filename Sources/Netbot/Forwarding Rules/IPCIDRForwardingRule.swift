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

import NEAddressProcessing
import NetbotLite
import NetbotLiteData
import Synchronization

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
struct IPCIDRForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  #if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
    typealias AvailableIPv6Pool = _AvailableIPv6Pool
  #endif

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

  @inline(__always) mutating func copyStorageIfNotUniquelyReferenced() {
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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
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

#if NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  @available(SwiftStdlib 5.5, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension IPCIDRForwardingRule._Storage: @unchecked Sendable {}

#if canImport(Darwin) && NETBOT_SWIFT_STDLIB_VERSION_MIN_REQUIRED_5_5
  #if canImport(FoundationEssentials)
    import FoundationEssentials
  #else
    import Foundation
  #endif

  @available(SwiftStdlib 5.5, *)
  extension IPv6Address {

    @available(SwiftStdlib 6.0, *)
    fileprivate var _address: UInt128 {
      rawValue.withUnsafeBytes {
        $0.load(as: UInt128.self)
      }
    }

    // swift-format-ignore: AlwaysUseLowerCamelCase
    @available(iOS, deprecated: 18.0)
    @available(macOS, deprecated: 15.0)
    @available(tvOS, deprecated: 18.0)
    @available(watchOS, deprecated: 11.0)
    @available(visionOS, deprecated: 2.0)
    fileprivate var __address: _UInt128 {
      rawValue.withUnsafeBytes {
        $0.load(as: _UInt128.self)
      }
    }
  }

  @available(SwiftStdlib 5.5, *)
  extension IPCIDRForwardingRule {

    struct _AvailableIPv6Pool: @unchecked Sendable {

      @available(SwiftStdlib 6.0, *)
      private var _bounds: (lower: UInt128, upper: UInt128) {
        bounds as! (lower: UInt128, upper: UInt128)
      }

      // swift-format-ignore: AlwaysUseLowerCamelCase
      @available(iOS, deprecated: 18.0)
      @available(macOS, deprecated: 15.0)
      @available(tvOS, deprecated: 18.0)
      @available(watchOS, deprecated: 11.0)
      @available(visionOS, deprecated: 2.0)
      private var __bounds: (lower: _UInt128, upper: _UInt128) {
        bounds as! (lower: _UInt128, upper: _UInt128)
      }

      private let bounds: Any

      /// Create new IPv6 pool with specific block of IPv6 adresses.
      ///
      /// - Important: Network and broadcast address will not be generated.
      ///
      /// - Parameter desired: A block of IPv6 addresses string (e.g. 192.168.0.1/16).
      init?(uncheckedBounds desired: String) {
        let components = desired.split(separator: "/")

        let bitWidth =
          if #available(SwiftStdlib 6.0, *) { UInt128.bitWidth } else {
            _UInt128.bitWidth
          }

        guard
          components.count == 2,
          case .ipv6(let address) = Address.Host(String(components[0])),
          let prefix = Int(components[1]),
          (0...bitWidth).contains(prefix)
        else {
          return nil
        }

        if #available(SwiftStdlib 6.0, *) {
          let subnetmask = (UInt128.max << (UInt128.bitWidth - prefix)).bigEndian
          let pointee = address.rawValue.withUnsafeBytes {
            $0.load(as: UInt128.self)
          }
          self.bounds = ((pointee & subnetmask).bigEndian, (pointee | ~subnetmask).bigEndian)
        } else {
          let subnetmask = (_UInt128.max << (_UInt128.bitWidth - prefix)).bigEndian
          let pointee = address.rawValue.withUnsafeBytes {
            $0.load(as: _UInt128.self)
          }
          self.bounds = ((pointee & subnetmask).bigEndian, (pointee | ~subnetmask).bigEndian)
        }
      }

      func contains(_ address: IPv6Address) -> Bool {
        if #available(SwiftStdlib 6.0, *) {
          return self._bounds.lower <= address._address.bigEndian
            && address._address.bigEndian <= self._bounds.upper
        } else {
          return self.__bounds.lower <= address.__address.bigEndian
            && address.__address.bigEndian <= self.__bounds.upper
        }
      }
    }
  }
#endif
