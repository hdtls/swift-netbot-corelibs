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
import NIOCore
import NetbotLite
import NetbotLiteData

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if os(Windows)
  import ucrt

  import struct WinSDK.ADDRESS_FAMILY
  import struct WinSDK.IN6_ADDR

  // swift-format-ignore: TypeNamesShouldBeCapitalized
  private typealias in6_addr = WinSDK.IN6_ADDR

  // swift-format-ignore: TypeNamesShouldBeCapitalized
  private typealias sa_family_t = WinSDK.ADDRESS_FAMILY
#elseif canImport(Darwin)
  import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
  #if canImport(Glibc)
    import Glibc
  #elseif canImport(Musl)
    import Musl
  #endif
  import CNIOLinux
#else
  #error("The Socket Addresses module was unable to identify your C library.")
#endif

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
struct IPCIDRForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  typealias AvailableIPv6Pool = _AvailableIPv6Pool

  @usableFromInline final class _Storage {
    @usableFromInline var v4: AvailableIPPool?
    @usableFromInline var v6: AvailableIPv6Pool?
    @usableFromInline var uncheckedBounds: String
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible

    @inlinable init(
      v4: AvailableIPPool?,
      v6: AvailableIPv6Pool?,
      uncheckedBounds: String,
      forwardProtocol: any ForwardProtocolConvertible
    ) {
      self.v4 = v4
      self.v6 = v6
      self.uncheckedBounds = uncheckedBounds
      self.forwardProtocol = forwardProtocol
    }

    @inlinable func copy() -> _Storage {
      _Storage(v4: v4, v6: v6, uncheckedBounds: uncheckedBounds, forwardProtocol: forwardProtocol)
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
    let v6 = AvailableIPv6Pool(uncheckedBounds: uncheckedBounds)
    let v4 = AvailableIPPool(uncheckedBounds: uncheckedBounds)
    self._storage = _Storage(
      v4: v4, v6: v6, uncheckedBounds: uncheckedBounds, forwardProtocol: forwardProtocol)
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
      case .ipv6:
        guard case .v6(let address) = try? address.asAddress() else { return false }
        return self._storage.v6?.contains(address) ?? false
      default: return false
      }
    }

    guard !eval(address) else { return true }

    guard let resolutions = connection.dnsResolutionReport?.resolutions else { return false }

    return resolutions.flatMap { $0.endpoints }.contains { eval($0) }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
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

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension IPCIDRForwardingRule._Storage: @unchecked Sendable {}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension IPCIDRForwardingRule {

  struct _AvailableIPv6Pool: Sendable {

    private let bounds: (lower: SocketAddress.IPv6Address, upper: SocketAddress.IPv6Address)

    var lower: SocketAddress.IPv6Address {
      bounds.lower
    }

    var upper: SocketAddress.IPv6Address {
      bounds.upper
    }

    init(bounds: (lower: SocketAddress.IPv6Address, upper: SocketAddress.IPv6Address)) {
      self.bounds = bounds
    }

    init?(uncheckedBounds desired: String) {
      let addressComponents = desired.split(separator: "/")
      guard addressComponents.count == 2 else {
        return nil
      }

      let ipAddress = addressComponents[0]
      guard let address = try? SocketAddress(ipAddress: String(ipAddress), port: 0) else {
        return nil
      }

      let prefixString = addressComponents[1]
      guard let prefix = Int(prefixString) else {
        return nil
      }

      var bitWidth = 128
      #if canImport(Darwin) && NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
        if #available(SwiftStdlib 6.0, *) {
          bitWidth = UInt128.bitWidth
        } else {
          bitWidth = _UInt128.bitWidth
        }
      #else
        bitWidth = UInt128.bitWidth
      #endif

      guard case .v6(let iPv6Address) = address, (0...bitWidth).contains(prefix) else {
        return nil
      }

      guard prefix != 0 else {
        let lowerBoundIPAddress = "0000:0000:0000:0000:0000:0000:0000:0000"
        let upperBoundIPAddress = "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"

        guard
          case .v6(let lowerBound) = try? SocketAddress(ipAddress: lowerBoundIPAddress, port: 0),
          case .v6(let upperBound) = try? SocketAddress(ipAddress: upperBoundIPAddress, port: 0)
        else {
          return nil
        }
        self.init(bounds: (lower: lowerBound, upper: upperBound))
        return
      }

      guard prefix != bitWidth else {
        self.init(bounds: (lower: iPv6Address, upper: iPv6Address))
        return
      }

      let bitsToMove = bitWidth - prefix
      var s6addr = iPv6Address.address.sin6_addr

      #if canImport(Darwin) && NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
        if #available(SwiftStdlib 6.0, *) {
          var packedAddress = withUnsafeBytes(of: &s6addr) {
            $0.loadUnaligned(as: UInt128.self).bigEndian
          }

          packedAddress = (packedAddress >> bitsToMove) << bitsToMove
          guard case .v6(let lowerBound) = SocketAddress(packedAddress: packedAddress.bigEndian)
          else {
            return nil
          }

          packedAddress = packedAddress | ~((UInt128.max >> bitsToMove) << bitsToMove)
          guard case .v6(let upperBound) = SocketAddress(packedAddress: packedAddress.bigEndian)
          else {
            return nil
          }
          self.init(bounds: (lower: lowerBound, upper: upperBound))
        } else {
          var packedAddress = withUnsafeBytes(of: &s6addr) {
            $0.loadUnaligned(as: _UInt128.self).bigEndian
          }

          packedAddress = (packedAddress >> bitsToMove) << bitsToMove
          guard case .v6(let lowerBound) = SocketAddress(packedAddress: packedAddress.bigEndian)
          else {
            return nil
          }

          packedAddress = packedAddress | ~((_UInt128.max >> bitsToMove) << bitsToMove)
          guard case .v6(let upperBound) = SocketAddress(packedAddress: packedAddress.bigEndian)
          else {
            return nil
          }
          self.init(bounds: (lower: lowerBound, upper: upperBound))
        }
      #else
        var packedAddress = withUnsafeBytes(of: &s6addr) {
          $0.loadUnaligned(as: UInt128.self).bigEndian
        }

        packedAddress = (packedAddress >> bitsToMove) << bitsToMove
        guard case .v6(let lowerBound) = SocketAddress(packedAddress: packedAddress.bigEndian)
        else {
          return nil
        }

        packedAddress = packedAddress | ~((UInt128.max >> bitsToMove) << bitsToMove)
        guard case .v6(let upperBound) = SocketAddress(packedAddress: packedAddress.bigEndian)
        else {
          return nil
        }
        self.init(bounds: (lower: lowerBound, upper: upperBound))
      #endif
    }

    func contains(_ address: SocketAddress.IPv6Address) -> Bool {
      var s6addr1 = address.address.sin6_addr
      var s6addr2 = lower.address.sin6_addr
      var s6addr3 = upper.address.sin6_addr
      let greatThanOrEqualToLowerBound =
        memcmp(&s6addr1, &s6addr2, MemoryLayout.size(ofValue: s6addr1)) >= 0
      let lessThanOrEqualToUpperBound =
        memcmp(&s6addr1, &s6addr3, MemoryLayout.size(ofValue: s6addr1)) <= 0
      return greatThanOrEqualToLowerBound && lessThanOrEqualToUpperBound
    }
  }
}

#if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
  @available(SwiftStdlib 5.3, *)
#else
  @available(SwiftStdlib 6.0, *)
#endif
extension SocketAddress {

  #if canImport(Darwin) && NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(iOS, deprecated: 18.0)
    @available(macOS, deprecated: 15.0)
    @available(tvOS, deprecated: 18.0)
    @available(watchOS, deprecated: 11.0)
    @available(visionOS, deprecated: 2.0)
    fileprivate init(packedAddress: _UInt128) {
      var ipv6Addr = sockaddr_in6()
      ipv6Addr.sin6_family = sa_family_t(AF_INET6)
      ipv6Addr.sin6_port = 0
      withUnsafeMutableBytes(of: &ipv6Addr.sin6_addr) {
        $0.storeBytes(of: packedAddress, as: _UInt128.self)
      }
      self.init(ipv6Addr)
    }
  #endif

  #if NETBOT_REQUIRES_SUPPORT_EARLY_OS_VERSIONS
    @available(SwiftStdlib 6.0, *)
  #endif
  fileprivate init(packedAddress: UInt128) {
    var ipv6Addr = sockaddr_in6()
    ipv6Addr.sin6_family = sa_family_t(AF_INET6)
    ipv6Addr.sin6_port = 0
    withUnsafeMutableBytes(of: &ipv6Addr.sin6_addr) {
      $0.storeBytes(of: packedAddress, as: UInt128.self)
    }
    self.init(ipv6Addr)
  }
}
