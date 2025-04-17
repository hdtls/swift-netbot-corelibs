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

  import let WinSDK.AF_INET
  import let WinSDK.AF_INET6

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

/// An `IPPacket` object represents the data, protocol family associated with an IP packet.
public enum IPPacket: Hashable, Sendable {

  public typealias Data = ByteBuffer

  case v4(IPv4Packet)

  case v6(IPv6Packet)

  /// The data content of the packet.
  public var data: Data {
    switch self {
    case .v4(let packet):
      return packet.data
    case .v6(let packet):
      return packet.data
    }
  }

  /// The protocol family of the packet (such as AF_INET or AF_INET6).
  public var protocolFamily: sa_family_t {
    switch self {
    case .v4(let packet):
      return packet.protocolFamily
    case .v6(let packet):
      return packet.protocolFamily
    }
  }

  /// Initializes a new IP packet object with data and protocol family.
  /// - Parameters:
  ///   - data: The content of the packet.
  ///   - protocolFamily: The protocol family of the packet (such as AF_INET or AF_INET6).
  public init?(data: Data, protocolFamily: sa_family_t) {
    switch protocolFamily {
    case sa_family_t(AF_INET):
      self = .v4(.init(data: data))
    case sa_family_t(AF_INET6):
      self = .v6(.init(data: data))
    default:
      return nil
    }
  }
}
