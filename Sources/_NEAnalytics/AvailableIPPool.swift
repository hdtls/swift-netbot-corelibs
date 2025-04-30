//
// See LICENSE.txt for license information
//

import Atomics
import NEAddressProcessing
import NIOCore

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if canImport(Darwin)
  import Darwin
#else
  import CNIOLinux
#endif

extension IPv4Address {

  fileprivate var _address: UInt32 {
    rawValue.withUnsafeBytes {
      $0.loadUnaligned(as: UInt32.self)
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

public struct AvailableIPPool: Sendable {

  private let _storage: ManagedAtomic<UInt32>
  private let bounds: (lower: UInt32, upper: UInt32)

  public var lower: IPv4Address {
    IPv4Address(bounds.lower)
  }

  public var upper: IPv4Address {
    IPv4Address(bounds.upper)
  }

  /// Create a new FakeIPPool with specific IP range.
  ///
  /// - Important: IP addresses lowerBound and upperBound is used for caculate range and will not be generated
  public init(bounds: (lower: IPv4Address, upper: IPv4Address)) {
    self.bounds = (bounds.lower._address.bigEndian, bounds.upper._address.bigEndian)
    _storage = .init(bounds.lower._address.bigEndian)
  }

  /// Create new FakeIPPool with specific block of IPv4 adresses.
  ///
  /// - Important: Network and broadcast address will not be generated.
  ///
  /// - Parameter desired: A block of IPv4 addresses string (e.g. 192.168.0.1/16).
  public init?(uncheckedBounds desired: String) {
    let components = desired.split(separator: "/")
    let addressComponents = components[0].split(separator: ".")
    guard addressComponents.count == 4 else {
      return nil
    }

    let address = try? SocketAddress(ipAddress: addressComponents.joined(separator: "."), port: 0)

    guard case .v4(let address) = address, let prefix = UInt32(components[1]), prefix <= 32 else {
      return nil
    }

    let subnetmask = (UInt32(0xFFFF_FFFF) << (32 - prefix)).bigEndian
    bounds = (
      (address.address.sin_addr.s_addr & subnetmask).bigEndian,
      (address.address.sin_addr.s_addr | ~subnetmask).bigEndian
    )
    // Skip network address.
    _storage = .init(bounds.lower)
  }

  /// Generate the usable IP excluding network and broadcast addresses.
  public func loadThenWrappingIncrement() -> IPv4Address {
    var address = _storage.loadThenWrappingIncrement(ordering: .relaxed)

    if address == bounds.lower {
      address = _storage.loadThenWrappingIncrement(ordering: .relaxed)
    }

    // Broadcast address should be skipped.
    if address == bounds.upper {
      _storage.store(bounds.lower &+ 1, ordering: .relaxed)
      address = _storage.loadThenWrappingIncrement(ordering: .relaxed)
    }

    let finalize = IPv4Address(address)
    return finalize
  }

  func store(_ desired: IPv4Address) {
    _storage.store(desired._address.bigEndian, ordering: .relaxed)
  }

  public func contains(_ address: IPv4Address) -> Bool {
    lower._address <= address._address && address._address <= upper._address
  }
}
