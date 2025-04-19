//
// See LICENSE.txt for license information
//

import NEAddressProcessing
import NIOCore

#if canImport(FoundationEssentials)
  import FoundationEssentials
#else
  import Foundation
#endif

#if os(Windows)
  import ucrt

  import let WinSDK.AF_INET6

  // swift-format-ignore: TypeNamesShouldBeCapitalized
  private typealias sa_family_t = WinSDK.ADDRESS_FAMILY
#elseif canImport(Darwin)
  import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
  #if canImport(Glibc)
    import Glibc
  #elseif canImport(Musl)
    import Musl
  #elseif canImport(Android)
    import Android
  #endif
  import CNIOLinux
#elseif canImport(WASILibc)
  import WASILibc
#else
  #error("The Socket Addresses module was unable to identify your C library.")
#endif

extension IPPacket {

  /// The class to process and build IPv6 packet.
  public struct IPv6Packet: Hashable, Sendable, CustomReflectable {

    public typealias Data = ByteBuffer

    /// The IP protocol family` AF_INET6`.
    public var protocolFamily: sa_family_t { sa_family_t(AF_INET6) }

    /// The IPv6 address of the sender of the packet.
    public var sourceAddress: IPv6Address {
      get {
        return IPv6Address(.init(_storage[8..<24]))!
      }
      set {
        _storage.replaceSubrange(8..<24, with: newValue.rawValue)
      }
    }

    /// The IPv6 address of the intended receiver of the packet.
    public var destinationAddress: IPv6Address {
      get {
        return IPv6Address(.init(_storage[24..<40]))!
      }
      set {
        _storage[24..<40] = Array(newValue.rawValue)
      }
    }

    /// IP packet data.
    public var data: Data {
      return _storage
    }

    private var _storage: Data

    init(data: Data) {
      self._storage = data

      // Ensure we have at least 20 bytes.
      let bytesNeeded = 40 - data.readableBytes
      if bytesNeeded > 0 {
        self._storage.writeRepeatingByte(0, count: bytesNeeded)
      }
    }

    public var customMirror: Mirror {
      Mirror(
        self,
        children: [
          "protocolFamily": protocolFamily,
          "sourceAddress": sourceAddress,
          "destinationAddress": destinationAddress,
          "data": data,
        ],
        displayStyle: .struct,
        ancestorRepresentation: .suppressed
      )
    }
  }
}
