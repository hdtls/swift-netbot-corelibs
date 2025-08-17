//
// See LICENSE.txt for license information
//

// swift-format-ignore-file

import Anlzr
import AnlzrReports
import NIOCore
#if canImport(FoundationEssentials)
import Foundation
import FoundationEssentials
#else
import Foundation
#endif

#if os(Windows)
  import ucrt

  import let WinSDK.AF_INET
  import let WinSDK.AF_INET6

  import let WinSDK.INET_ADDRSTRLEN
  import let WinSDK.INET6_ADDRSTRLEN

  import func WinSDK.FreeAddrInfoW
  import func WinSDK.GetAddrInfoW

  import struct WinSDK.ADDRESS_FAMILY
  import struct WinSDK.ADDRINFOW
  import struct WinSDK.IN_ADDR
  import struct WinSDK.IN6_ADDR

  import struct WinSDK.sockaddr
  import struct WinSDK.sockaddr_in
  import struct WinSDK.sockaddr_in6
  import struct WinSDK.sockaddr_storage
  import struct WinSDK.sockaddr_un

  import typealias WinSDK.u_short

  private typealias in_addr = WinSDK.IN_ADDR
  private typealias in6_addr = WinSDK.IN6_ADDR
  private typealias in_port_t = WinSDK.u_short
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

struct IPCIDRForwardingRule: ForwardingRule, ForwardingRuleConvertible, Hashable, Sendable {

  @usableFromInline final class _Storage {
    @usableFromInline var classlessInterDomainRouting: String
    @usableFromInline var addresses: Addresses?
    @usableFromInline var forwardProtocol: any ForwardProtocolConvertible

    @inlinable init(classlessInterDomainRouting: String, addresses: Addresses?, forwardProtocol: any ForwardProtocolConvertible) {
      self.classlessInterDomainRouting = classlessInterDomainRouting
      self.addresses = try? Addresses(cidr: classlessInterDomainRouting)
      self.forwardProtocol = forwardProtocol
    }

    @inlinable func copy() -> _Storage {
      _Storage(
        classlessInterDomainRouting: classlessInterDomainRouting,
        addresses: addresses,
        forwardProtocol: forwardProtocol
      )
    }
  }

  @usableFromInline var _storage: _Storage

  let requireIPAddress = true

  @inlinable var forwardProtocol: any ForwardProtocolConvertible {
    get { _storage.forwardProtocol }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.forwardProtocol = newValue
    }
  }

  @inlinable var description: String {
    "IP-CIDR,\(classlessInterDomainRouting),\(forwardProtocol.asForwardProtocol().name)"
  }

  /// IP CIDR string.
  @inlinable var classlessInterDomainRouting: String {
    get { _storage.classlessInterDomainRouting }
    set {
      copyStorageIfNotUniquelyReferenced()
      _storage.classlessInterDomainRouting = newValue
      _storage.addresses = try? Addresses(cidr: newValue)
    }
  }

  private var addresses: Addresses? {
    _storage.addresses
  }

  @inlinable init(classlessInterDomainRouting: String, forwardProtocol: any ForwardProtocolConvertible) {
    let addresses = try? Addresses(cidr: classlessInterDomainRouting)
    self._storage = _Storage(
      classlessInterDomainRouting: classlessInterDomainRouting,
      addresses: addresses,
      forwardProtocol: forwardProtocol
    )
  }

  @usableFromInline mutating func copyStorageIfNotUniquelyReferenced() {
    if !isKnownUniquelyReferenced(&self._storage) {
      self._storage = self._storage.copy()
    }
  }

  @inlinable func predicate(_ connection: Connection) throws -> Bool {
    guard let host = connection.originalRequest?.host(percentEncoded: false) else {
      return false
    }

    guard let address = try? SocketAddress(ipAddress: host, port: 0) else {
      return false
    }

    return addresses?.contains(address) == true
  }
}

extension IPCIDRForwardingRule._Storage: Hashable {
  static func == (lhs: IPCIDRForwardingRule._Storage, rhs: IPCIDRForwardingRule._Storage) -> Bool {
    lhs.classlessInterDomainRouting == rhs.classlessInterDomainRouting
    && lhs.addresses == rhs.addresses
    && lhs.forwardProtocol.asForwardProtocol().name == rhs.forwardProtocol.asForwardProtocol().name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(classlessInterDomainRouting)
    hasher.combine(addresses)
    hasher.combine(forwardProtocol.asForwardProtocol().name)
  }
}

extension IPCIDRForwardingRule._Storage: @unchecked Sendable {}

extension IPCIDRForwardingRule {

  struct Addresses: Hashable, Sendable {
    let lowerBound: SocketAddress
    let upperBound: SocketAddress

    init(lowerBound: SocketAddress, upperBound: SocketAddress) {
      self.lowerBound = lowerBound
      self.upperBound = upperBound
    }

    init(cidr: String) throws {
      guard let delimiterRange = cidr.range(of: "/") else {
        throw SocketAddressError.failedToParseIPString(cidr)
      }
      guard delimiterRange.upperBound < cidr.endIndex else {
        throw SocketAddressError.failedToParseIPString(cidr)
      }

      let ipAddress = cidr[..<delimiterRange.lowerBound]
      let address = try SocketAddress(ipAddress: String(ipAddress), port: 0)

      let prefixString = cidr[delimiterRange.upperBound...]
      guard let prefix = Int(prefixString) else {
        throw SocketAddressError.failedToParseIPString(cidr)
      }

      switch address {
      case .v4:
        guard (0...UInt32.bitWidth).contains(prefix) else {
          throw SocketAddressError.failedToParseIPString(cidr)
        }
        try self.init(address: address, maskBits: prefix)
      case .v6:
        guard (0...128).contains(prefix) else {
          throw SocketAddressError.failedToParseIPString(cidr)
        }
        try self.init(address: address, maskBits: prefix)
      case .unixDomainSocket:
        throw SocketAddressError.unsupported
      }
    }

    init(address: SocketAddress, maskBits prefix: Int) throws {
      switch address {
      case .v4(let iPv4Address):
        precondition((0...UInt32.bitWidth).contains(prefix))

        guard prefix != 0 else {
          lowerBound = try SocketAddress(ipAddress: "0.0.0.0", port: 0)
          upperBound = try SocketAddress(ipAddress: "255.255.255.255", port: 0)
          return
        }

        guard prefix != UInt32.bitWidth else {
          lowerBound = address
          upperBound = address
          return
        }

        let bitsToMove = UInt32.bitWidth - prefix
        #if os(Windows)
          var packedAddress = iPv4Address.address.sin_addr.S_un.S_addr.bigEndian
        #else
          var packedAddress = iPv4Address.address.sin_addr.s_addr.bigEndian
        #endif

        packedAddress = (packedAddress >> bitsToMove) << bitsToMove
        lowerBound = .init(packedAddress: packedAddress.bigEndian)

        packedAddress = packedAddress | ~((UInt32.max >> bitsToMove) << bitsToMove)
        upperBound = .init(packedAddress: packedAddress.bigEndian)
      case .v6(let iPv6Address):
        var bitWidth = 128
        #if canImport(Darwin)
          if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            bitWidth = UInt128.bitWidth
          } else {
            bitWidth = _UInt128.bitWidth
          }
        #else
          bitWidth = UInt128.bitWidth
        #endif

        precondition((0...bitWidth).contains(prefix))

        guard prefix != 0 else {
          let lowerBoundIPAddress = "0000:0000:0000:0000:0000:0000:0000:0000"
          let upperBoundIPAddress = "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"

          lowerBound = try SocketAddress(ipAddress: lowerBoundIPAddress, port: 0)
          upperBound = try SocketAddress(ipAddress: upperBoundIPAddress, port: 0)
          return
        }

        guard prefix != bitWidth else {
          lowerBound = address
          upperBound = address
          return
        }

        let bitsToMove = bitWidth - prefix
        var s6addr = iPv6Address.address.sin6_addr

        #if canImport(Darwin)
          if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            var packedAddress = withUnsafeBytes(of: &s6addr) {
              $0.loadUnaligned(as: UInt128.self).bigEndian
            }

            packedAddress = (packedAddress >> bitsToMove) << bitsToMove
            lowerBound = .init(packedAddress: packedAddress.bigEndian)

            packedAddress = packedAddress | ~((UInt128.max >> bitsToMove) << bitsToMove)
            upperBound = .init(packedAddress: packedAddress.bigEndian)
          } else {
            var packedAddress = withUnsafeBytes(of: &s6addr) {
              $0.loadUnaligned(as: _UInt128.self).bigEndian
            }

            packedAddress = (packedAddress >> bitsToMove) << bitsToMove
            lowerBound = .init(packedAddress: packedAddress.bigEndian)

            packedAddress = packedAddress | ~((_UInt128.max >> bitsToMove) << bitsToMove)
            upperBound = .init(packedAddress: packedAddress.bigEndian)
          }
        #else
          var packedAddress = withUnsafeBytes(of: &s6addr) {
            $0.loadUnaligned(as: UInt128.self).bigEndian
          }

          packedAddress = (packedAddress >> bitsToMove) << bitsToMove
          lowerBound = .init(packedAddress: packedAddress.bigEndian)

          packedAddress = packedAddress | ~((UInt128.max >> bitsToMove) << bitsToMove)
          upperBound = .init(packedAddress: packedAddress.bigEndian)
        #endif
      case .unixDomainSocket:
        throw SocketAddressError.unsupported
      }
    }

    func contains(_ address: SocketAddress) -> Bool {
      switch (address, lowerBound, upperBound) {
      case (.v4(let iPv4Address), .v4(let lowerBoundAddress), .v4(let upperBoundAddress)):
        #if os(Windows)
          let target = iPv4Address.address.sin_addr.S_un.S_addr.byteSwapped
          let lowerBound = lowerBoundAddress.address.sin_addr.S_un.S_addr.byteSwapped
          let upperBound = upperBoundAddress.address.sin_addr.S_un.S_addr.byteSwapped
        #else
          let target = iPv4Address.address.sin_addr.s_addr.byteSwapped
          let lowerBound = lowerBoundAddress.address.sin_addr.s_addr.byteSwapped
          let upperBound = upperBoundAddress.address.sin_addr.s_addr.byteSwapped
        #endif
        return target >= lowerBound && target <= upperBound
      case (.v6(let iPv6Address), .v6(let lowerBoundAddress), .v6(let upperBoundAddress)):
        var s6addr1 = iPv6Address.address.sin6_addr
        var s6addr2 = lowerBoundAddress.address.sin6_addr
        var s6addr3 = upperBoundAddress.address.sin6_addr
        let greatThanOrEqualToLowerBound =
          memcmp(&s6addr1, &s6addr2, MemoryLayout.size(ofValue: s6addr1)) >= 0
        let lessThanOrEqualToUpperBound =
          memcmp(&s6addr1, &s6addr3, MemoryLayout.size(ofValue: s6addr1)) <= 0
        return greatThanOrEqualToLowerBound && lessThanOrEqualToUpperBound
      default:
        return false
      }
    }
  }
}

extension SocketAddress {

  fileprivate init(packedAddress: UInt32) {
    var ipv4Addr = sockaddr_in()
    ipv4Addr.sin_family = sa_family_t(AF_INET)
    ipv4Addr.sin_port = 0
    withUnsafeMutableBytes(of: &ipv4Addr.sin_addr) {
      $0.storeBytes(of: packedAddress, as: UInt32.self)
    }
    self.init(ipv4Addr)
  }

  #if canImport(Darwin)
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

  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
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
