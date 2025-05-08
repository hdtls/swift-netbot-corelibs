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

protocol NEIPFieldsProtocol<Data> {

  associatedtype Data

  /// The IP protocol family` NIOBSDSocket.AddressFamily`.
  var protocolFamily: NIOBSDSocket.AddressFamily { get }

  /// The IP fields data.
  var data: Data { get }

  /// A boolean value determinse whether this IP headers has modified it's fields.
  var hasModified: Bool { get }
}

public enum NEIPFields: NEIPFieldsProtocol, Hashable, Sendable {

  typealias Data = ByteBuffer

  /// The class to process and build IPv4 packet.
  public struct NEInFields: NEIPFieldsProtocol, Hashable, Sendable, CustomReflectable {

    public typealias Data = ByteBuffer

    public var protocolFamily: NIOBSDSocket.AddressFamily { .inet }

    /// The IPv4 header is variable in size due to the optional 14th field (Options). The IHL field contains the size of the IPv4 header;
    /// it has 4 bits that specify the number of 32-bit words in the header.
    ///
    /// The minimum value for this field is 5, which indicates a length of 5 × 32 bits = 160 bits = 20 bytes. As a 4-bit field, the
    /// maximum value is 15; this means that the maximum size of the IPv4 header is 15 × 32 bits = 480 bits = 60 bytes.
    public var internetHeaderLength: UInt8 {
      self._internetHeaderLength
    }
    private var _internetHeaderLength: UInt8 {
      get {
        self._storage[self._storage.startIndex] & 0b0000_1111
      }
      set {
        precondition(newValue <= 0b0000_1111)
        precondition(newValue >= 5)
        let newValue = self._storage[self._storage.startIndex] & 0b1111_0000 | UInt8(newValue)
        self._storage[_storage.startIndex] = newValue
        self._hasModified()
      }
    }

    /// DSCP originally defined as the type of service (ToS), this field specifies differentiated services (DiffServ).
    public var differentiatedServicesCodePoint: UInt8 {
      get {
        return (self._storage[self._storage.index(after: self._storage.startIndex)] >> 2)
          & 0b0011_1111
      }
      set {
        // Ensure DSCP is valid (6-bit value)
        let validatedDSCP = min(newValue, 0x3F)
        let index = self._storage.index(after: self._storage.startIndex)
        self._storage[index] = (validatedDSCP << 2) | self.explicitCongestionNotification
        self._hasModified()
      }
    }

    /// This field allows end-to-end notification of network congestion without dropping packets.
    /// ECN is an optional feature available when both endpoints support it and effective when also supported by the underlying network.
    public var explicitCongestionNotification: UInt8 {
      get {
        return self._storage[self._storage.index(after: self._storage.startIndex)] & 0b0000_0011
      }
      set {
        let position = self._storage.index(after: self._storage.startIndex)
        let validatedECN = min(newValue, 0b000_0011)
        var dscpAndECN = self._storage[position]
        // Clear ECN and set new value
        dscpAndECN &= 0xFC
        dscpAndECN |= validatedECN
        self._storage[position] = dscpAndECN
        self._hasModified()
      }
    }

    /// This 16-bit field defines the entire packet size in bytes, including header and data.
    public var totalLength: UInt16 {
      get {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 2)
        return self._storage.getInteger(at: position, as: UInt16.self)!
      }
      set {
        precondition(newValue >= internetHeaderLength * 4)
        let position = self._storage.index(self._storage.startIndex, offsetBy: 2)
        self._storage.setInteger(UInt16(newValue), at: position)
        self._hasModified()
      }
    }

    /// Identification field and is primarily used for uniquely identifying the group of fragments of a single IP datagram.
    public var identification: UInt16 {
      get {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 4)
        return self._storage.getInteger(at: position)!
      }
      set {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 4)
        self._storage.setInteger(newValue, at: position)
        self._hasModified()
      }
    }

    /// There are three flags defined within this field, R, DF and MF.
    public var flags: UInt8 {
      get {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 6)
        let flagsAndFragmentOffset = self._storage.getInteger(at: position, as: UInt16.self)!
        return UInt8((flagsAndFragmentOffset >> 13) & 0x7)
      }
      set {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 6)
        let flags = UInt16(newValue) << 13
        self._storage.setInteger(flags | fragmentOffset, at: position)
        self._hasModified()
      }
    }

    ///  the offset of a particular fragment relative to the beginning of the original unfragmented IP datagram.
    public var fragmentOffset: UInt16 {
      get {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 6)
        let flagsAndFragmentOffset = self._storage.getInteger(at: position, as: UInt16.self)!
        return flagsAndFragmentOffset & 0x1FFF
      }
      set {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 6)
        let flags = UInt16(flags) << 13
        let validatedOffset = min(newValue, 0x1FFF)
        self._storage.setInteger(flags | validatedOffset, at: position)
        self._hasModified()
      }
    }

    /// The datagram's lifetime to prevent network failure in the event of a routing loop.
    public var timeToLive: Int {
      get {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 8)
        return Int(self._storage.getInteger(at: position, as: UInt8.self)!)
      }
      set {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 8)
        self._storage.setInteger(UInt8(newValue), at: position)
        self._hasModified()
      }
    }

    /// Protocol used in the data portion of the IP datagram.
    public var `protocol`: NIOIPProtocol {
      get {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 9)
        return NIOIPProtocol(rawValue: self._storage.getInteger(at: position)!)
      }
      set {
        let position = self._storage.index(self._storage.startIndex, offsetBy: 9)
        self._storage.setInteger(newValue.rawValue, at: position)
        self._hasModified()
      }
    }

    /// The IPv4 header checksum used for error checking of the header.
    public var chksum: UInt16 {
      _chksum(self._storage, zeroization: true)
    }

    /// The IPv4 address of the sender of the packet.
    public var sourceAddress: IPv4Address {
      get {
        return IPv4Address(.init(self._storage[12..<16]))!
      }
      set {
        self._storage.replaceSubrange(12..<16, with: newValue.rawValue)
        self._hasModified()
      }
    }

    /// The IPv4 address of the intended receiver of the packet.
    public var destinationAddress: IPv4Address {
      get {
        return IPv4Address(.init(self._storage[16..<20]))!
      }
      set {
        self._storage[16..<20] = Array(newValue.rawValue)
        self._hasModified()
      }
    }

    /// Internet protocol options.
    public var options: Data? {
      get {
        guard self.internetHeaderLength > 5 else {
          return nil
        }
        let position = self._storage.index(self._storage.startIndex, offsetBy: 20)
        let length = self.internetHeaderLength * 4 - 20
        return self._storage.getSlice(at: position, length: Int(length))
      }
      set {
        guard var newValue else {
          guard let options else {
            // Do nothing if original packet does not contains options.
            return
          }
          self._storage.removeSubrange(20..<20 + options.count)
          self._internetHeaderLength = 5
          self.totalLength -= UInt16(options.count)
          self._hasModified()
          return
        }

        // IHL is always a multiple of 4, so if new options data count is not multiple of 4
        // we need fill zero to make it a multiple of 4.
        if newValue.count % 4 != 0 {
          let bytesNeeded = 4 - newValue.count % 4
          newValue.append(contentsOf: Array(repeating: UInt8.zero, count: bytesNeeded))
        }

        guard let options else {
          self._storage.insert(contentsOf: newValue, at: 20)
          self._internetHeaderLength = UInt8(5 + newValue.count / 4)
          self.totalLength += UInt16(newValue.count)
          self._hasModified()
          return
        }

        self._storage.replaceSubrange(20..<20 + options.count, with: newValue)
        self._internetHeaderLength = UInt8(5 + newValue.count / 4)
        if newValue.count > options.count {
          self.totalLength += UInt16(newValue.count - options.count)
        } else {
          self.totalLength -= UInt16(options.count - newValue.count)
        }
        self._hasModified()
      }
    }

    /// IP header fields data.
    public var data: Data {
      self._storage
    }

    private var _storage: Data

    init(storage: Data) {
      let headerLength = Int(storage[storage.startIndex] & 0b0000_1111) * 4
      assert(headerLength <= storage.count)
      self._storage = storage.prefix(headerLength)

      assert(self._internetHeaderLength >= 5)
      assert(self.totalLength >= self._internetHeaderLength * 4)
      assert((self._internetHeaderLength - 5) * 4 == self.options?.count ?? 0)
    }

    var hasModified: Bool = false

    private mutating func _hasModified() {
      self.hasModified = true
      self._storage.setInteger(chksum, at: self._storage.startIndex.advanced(by: 10))
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
          "data": data,
        ],
        displayStyle: .struct,
        ancestorRepresentation: .suppressed
      )
    }
  }

  public struct NEIn6Fields: NEIPFieldsProtocol, Hashable, Sendable {

    public typealias Data = ByteBuffer

    public var protocolFamily: NIOBSDSocket.AddressFamily { .inet6 }

    public var data: Data {
      _storage
    }

    private var _storage: Data

    init(storage: Data) {
      self._storage = storage
    }

    var hasModified: Bool = false
  }

  case v4(NEInFields)
  case v6(NEIn6Fields)

  var protocolFamily: NIOBSDSocket.AddressFamily {
    switch self {
    case .v4(let fields):
      return fields.protocolFamily
    case .v6(let fields):
      return fields.protocolFamily
    }
  }

  var data: Data {
    switch self {
    case .v4(let fields):
      return fields.data
    case .v6(let fields):
      return fields.data
    }
  }

  init?(storage: Data) {
    switch storage[storage.startIndex] >> 4 {
    case 4:
      self = .v4(.init(storage: storage))
    case 6:
      self = .v6(.init(storage: storage))
    default:
      return nil
    }
  }

  var hasModified: Bool {
    switch self {
    case .v4(let fields):
      return fields.hasModified
    case .v6(let fields):
      return fields.hasModified
    }
  }
}
