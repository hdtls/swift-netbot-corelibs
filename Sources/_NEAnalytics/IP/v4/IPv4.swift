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

extension IPPacket {

  /// The class to process and build IPv4 packet.
  public struct IPv4Packet: Hashable, Sendable, CustomReflectable {

    public typealias Data = ByteBuffer

    /// The IP protocol family` AF_INET`.
    public var protocolFamily: sa_family_t { sa_family_t(AF_INET) }

    /// The IPv4 header is variable in size due to the optional 14th field (Options). The IHL field contains the size of the IPv4 header;
    /// it has 4 bits that specify the number of 32-bit words in the header.
    ///
    /// The minimum value for this field is 5, which indicates a length of 5 × 32 bits = 160 bits = 20 bytes. As a 4-bit field, the
    /// maximum value is 15; this means that the maximum size of the IPv4 header is 15 × 32 bits = 480 bits = 60 bytes.
    public var internetHeaderLength: Int {
      get {
        Int(_storage[_storage.startIndex] & 0b0000_1111)
      }
      set {
        precondition(newValue <= 15)
        precondition(newValue >= 5)
        let newValue = _storage[_storage.startIndex] & 0b1111_0000 | UInt8(newValue)
        _storage[_storage.startIndex] = newValue
      }
    }

    /// DSCP originally defined as the type of service (ToS), this field specifies differentiated services (DiffServ).
    public var differentiatedServicesCodePoint: UInt8 {
      get {
        return (_storage[_storage.index(after: _storage.startIndex)] >> 2) & 0b0011_1111
      }
      set {
        // Ensure DSCP is valid (6-bit value)
        let validatedDSCP = min(newValue, 0x3F)
        let index = _storage.index(after: _storage.startIndex)
        _storage[index] = (validatedDSCP << 2) | explicitCongestionNotification
      }
    }

    /// This field allows end-to-end notification of network congestion without dropping packets.
    /// ECN is an optional feature available when both endpoints support it and effective when also supported by the underlying network.
    public var explicitCongestionNotification: UInt8 {
      get {
        return _storage[_storage.index(after: _storage.startIndex)] & 0b0000_0011
      }
      set {
        let position = _storage.index(after: _storage.startIndex)
        let validatedECN = min(newValue, 0b000_0011)
        var dscpAndECN = _storage[position]
        // Clear ECN and set new value
        dscpAndECN &= 0xFC
        dscpAndECN |= validatedECN
        _storage[position] = dscpAndECN
      }
    }

    /// This 16-bit field defines the entire packet size in bytes, including header and data.
    public var totalLength: Int {
      get {
        let position = _storage.index(_storage.readerIndex, offsetBy: 2)
        return Int(_storage.getInteger(at: position, as: UInt16.self)!)
      }
      set {
        precondition(newValue <= UInt16.max)
        precondition(newValue >= 20)
        precondition(newValue >= internetHeaderLength)
        let position = _storage.index(_storage.readerIndex, offsetBy: 2)
        _storage.setInteger(UInt16(newValue), at: position)
      }
    }

    /// Identification field and is primarily used for uniquely identifying the group of fragments of a single IP datagram.
    public var identification: UInt16 {
      get {
        let position = _storage.index(_storage.readerIndex, offsetBy: 4)
        return _storage.getInteger(at: position)!
      }
      set {
        let position = _storage.index(_storage.readerIndex, offsetBy: 4)
        _storage.setInteger(newValue, at: position)
      }
    }

    /// There are three flags defined within this field, R, DF and MF.
    public var flags: UInt8 {
      get {
        let position = _storage.index(_storage.readerIndex, offsetBy: 6)
        let flagsAndFragmentOffset = _storage.getInteger(at: position, as: UInt16.self)!
        return UInt8((flagsAndFragmentOffset >> 13) & 0x7)
      }
      set {
        let position = _storage.index(_storage.readerIndex, offsetBy: 6)
        let flags = UInt16(newValue) << 13
        _storage.setInteger(flags | fragmentOffset, at: position)
      }
    }

    ///  the offset of a particular fragment relative to the beginning of the original unfragmented IP datagram.
    public var fragmentOffset: UInt16 {
      get {
        let position = _storage.index(_storage.readerIndex, offsetBy: 6)
        let flagsAndFragmentOffset = _storage.getInteger(at: position, as: UInt16.self)!
        return flagsAndFragmentOffset & 0x1FFF
      }
      set {
        let position = _storage.index(_storage.readerIndex, offsetBy: 6)
        let flags = UInt16(flags) << 13
        let validatedOffset = min(newValue, 0x1FFF)
        _storage.setInteger(flags | validatedOffset, at: position)
      }
    }

    /// The datagram's lifetime to prevent network failure in the event of a routing loop.
    public var timeToLive: Int {
      get {
        let position = _storage.index(_storage.readerIndex, offsetBy: 8)
        return Int(_storage.getInteger(at: position, as: UInt8.self)!)
      }
      set {
        let position = _storage.index(_storage.readerIndex, offsetBy: 8)
        _storage.setInteger(UInt8(newValue), at: position)
      }
    }

    /// Protocol used in the data portion of the IP datagram.
    public var `protocol`: NIOIPProtocol {
      get {
        let position = _storage.index(_storage.readerIndex, offsetBy: 9)
        return NIOIPProtocol(rawValue: _storage.getInteger(at: position)!)
      }
      set {
        let position = _storage.index(_storage.readerIndex, offsetBy: 9)
        _storage.setInteger(newValue.rawValue, at: position)
      }
    }

    /// The IPv4 header checksum used for error checking of the header.
    public var chksum: UInt16 {
      let data = _storage.getSlice(at: _storage.readerIndex, length: internetHeaderLength * 4)!
      return _chksum(data, zeroization: true)
    }

    /// The IPv4 address of the sender of the packet.
    public var sourceAddress: IPv4Address {
      get {
        return IPv4Address(.init(_storage[12..<16]))!
      }
      set {
        _storage.replaceSubrange(12..<16, with: newValue.rawValue)
      }
    }

    /// The IPv4 address of the intended receiver of the packet.
    public var destinationAddress: IPv4Address {
      get {
        return IPv4Address(.init(_storage[16..<20]))!
      }
      set {
        _storage[16..<20] = Array(newValue.rawValue)
      }
    }

    /// Internet protocol options.
    public var options: Data? {
      get {
        guard internetHeaderLength > 5 else {
          return nil
        }
        let position = _storage.index(_storage.readerIndex, offsetBy: 20)
        let length = internetHeaderLength * 4 - 20
        return _storage.getSlice(at: position, length: length)
      }
      set {
        guard var newValue else {
          guard let options else {
            // Do nothing if original packet does not contains options.
            return
          }
          _storage.removeSubrange(20..<20 + options.count)
          internetHeaderLength = 5
          totalLength = _storage.count
          return
        }

        // IHL is always a multiple of 4, so if new options data count is not multiple of 4
        // we need fill zero to make it a multiple of 4.
        if newValue.count % 4 != 0 {
          let bytesNeeded = 4 - newValue.count % 4
          newValue.append(contentsOf: Array(repeating: UInt8.zero, count: bytesNeeded))
        }

        guard let options else {
          _storage.insert(contentsOf: newValue, at: 20)
          internetHeaderLength = 5 + newValue.count / 4
          totalLength = _storage.count
          return
        }

        _storage.replaceSubrange(20..<20 + options.count, with: newValue)
        internetHeaderLength = 5 + newValue.count / 4
        totalLength = _storage.count
      }
    }

    /// Transport layer data.
    public var payload: Data? {
      get {
        let l = internetHeaderLength * 4
        guard _storage.count > l else {
          return nil
        }
        return _storage[l...]
      }
      set {
        guard let newValue else {
          _storage.removeSubrange((internetHeaderLength * 4)...)
          totalLength = internetHeaderLength * 4
          return
        }
        _storage[(internetHeaderLength * 4)...] = newValue
        totalLength = _storage.readableBytes
      }
    }

    /// IP packet data.
    public var data: Data {
      var data = _storage
      data.setInteger(chksum, at: data.readerIndex.advanced(by: 10))
      return data
    }

    private var _storage: Data

    init(data: Data) {
      self._storage = data

      // Ensure we have at least 20 bytes.
      let bytesNeeded = 20 - data.readableBytes
      if bytesNeeded > 0 {
        self._storage.writeRepeatingByte(0, count: bytesNeeded)
      }
    }

    public var customMirror: Mirror {
      Mirror(
        self,
        children: [
          "protocolFamily": protocolFamily,
          "internetHeaderLength": internetHeaderLength,
          "differentiatedServicesCodePoint": differentiatedServicesCodePoint,
          "explicitCongestionNotification": explicitCongestionNotification,
          "totalLength": totalLength,
          "identification": identification,
          "flags": flags,
          "fragmentOffset": fragmentOffset,
          "timeToLive": timeToLive,
          "protocol": `protocol`,
          "chksum": chksum,
          "sourceAddress": sourceAddress,
          "destinationAddress": destinationAddress,
          "options": options as Any,
          "payload": payload as Any,
          "data": data,
        ],
        displayStyle: .struct,
        ancestorRepresentation: .suppressed
      )
    }
  }
}
