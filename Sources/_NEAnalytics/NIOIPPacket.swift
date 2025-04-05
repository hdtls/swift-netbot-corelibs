//
// See LICENSE.txt for license information
//

#if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  #if canImport(FoundationEssentials)
    public import FoundationEssentials
  #else
    public import Foundation
  #endif
  public import NEAddressProcessing
  public import NIOCore

  /// An `IPPacket` object represents the data, protocol family associated with an IP packet.
  public enum NIOIPPacket: Hashable, Sendable {

    /// The class to process and build IPv4 packet.
    public struct IPv4Packet: Hashable, CustomReflectable, Sendable {

      /// The IP protocol family` AF_INET` and `AF_INET6`.
      public var protocolFamily: sa_family_t {
        sa_family_t(AF_INET)
      }

      /// The IPv4 header is variable in size due to the optional 14th field (Options). The IHL field contains the size of the IPv4 header;
      /// it has 4 bits that specify the number of 32-bit words in the header.
      ///
      /// The minimum value for this field is 5, which indicates a length of 5 × 32 bits = 160 bits = 20 bytes. As a 4-bit field, the
      /// maximum value is 15; this means that the maximum size of the IPv4 header is 15 × 32 bits = 480 bits = 60 bytes.
      public var internetHeaderLength: Int {
        get { Int(_storage[0] & 0b0000_1111) }
        set {
          precondition(newValue <= 15)
          precondition(newValue >= 5)
          let newValue = _storage[0] & 0b1111_0000 | UInt8(newValue)
          _storage.replaceSubrange(0..<1, with: Data([newValue]))
        }
      }

      /// DSCP originally defined as the type of service (ToS), this field specifies differentiated services (DiffServ).
      public var differentiatedServicesCodePoint: UInt8 {
        get { _storage[1] >> 2 }
        set {
          let newValue = (newValue << 2) | (_storage[1] & 0b0000_0011)
          _storage.replaceSubrange(1..<2, with: Data([newValue]))
          isModified = true
        }
      }

      /// This field allows end-to-end notification of network congestion without dropping packets.
      /// ECN is an optional feature available when both endpoints support it and effective when also supported by the underlying network.
      public var explicitCongestionNotification: UInt8 {
        get {
          _storage[1] & 0b0000_0011
        }
        set {
          let newValue = (newValue & 0b0000_0011) | _storage[1] & 0b1111_1100
          _storage.replaceSubrange(1..<2, with: Data([newValue]))
        }
      }

      /// This 16-bit field defines the entire packet size in bytes, including header and data.
      public var totalLength: Int {
        get {
          _storage.subdata(in: 2..<4).withUnsafeBytes {
            Int($0.load(as: UInt16.self).bigEndian)
          }
        }
        set {
          precondition(newValue <= UInt16.max)
          precondition(newValue >= 20)
          precondition(newValue >= internetHeaderLength)
          var newValue = UInt16(newValue).bigEndian
          withUnsafeBytes(of: &newValue) {
            _storage.replaceSubrange(2..<4, with: Data($0))
          }
          isModified = true
        }
      }

      /// Identification field and is primarily used for uniquely identifying the group of fragments of a single IP datagram.
      public var identification: UInt16 {
        get {
          _storage.subdata(in: 4..<6).withUnsafeBytes {
            $0.load(as: UInt16.self).bigEndian
          }
        }
        set {
          var newValue = newValue.bigEndian
          withUnsafeBytes(of: &newValue) {
            _storage.replaceSubrange(4..<6, with: Data($0))
          }
        }
      }

      /// There are three flags defined within this field, R, DF and MF.
      public var flags: UInt8 {
        get { _storage[6] >> 5 }
        set {
          let newValue = (newValue << 5) | (_storage[6] & 0b0001_1111)
          _storage.replaceSubrange(6..<7, with: Data([newValue]))
        }
      }

      ///  the offset of a particular fragment relative to the beginning of the original unfragmented IP datagram.
      public var fragmentOffset: UInt16 {
        get {
          _storage.subdata(in: 6..<8).withUnsafeBytes {
            $0.load(as: UInt16.self).bigEndian & 0x1FFF
          }
        }
        set {
          var newValue = ((UInt16(flags) << 13) | newValue).bigEndian
          withUnsafeBytes(of: &newValue) {
            _storage.replaceSubrange(6..<8, with: Data($0))
          }
        }
      }

      /// The datagram's lifetime to prevent network failure in the event of a routing loop.
      public var timeToLive: Int {
        get { Int(_storage[8]) }
        set {
          assert(newValue <= UInt8.max)
          _storage.replaceSubrange(8..<9, with: Data([UInt8(newValue)]))
        }
      }

      /// Protocol used in the data portion of the IP datagram.
      public var `protocol`: NIOIPProtocol {
        get { NIOIPProtocol(rawValue: _storage[9]) }
        set {
          _storage.replaceSubrange(9..<10, with: Data([newValue.rawValue]))
        }
      }

      /// The IPv4 header checksum used for error checking of the header.
      public var headerChecksum: UInt16 {
        var data = _storage
        data.replaceSubrange(10..<12, with: Data([0, 0]))
        return chksum(data, length: internetHeaderLength * 4)
      }

      /// The IPv4 address of the sender of the packet.
      public var sourceAddress: IPv4Address {
        get {
          IPv4Address(_storage.subdata(in: 12..<16))!
        }
        set {
          _storage.replaceSubrange(12..<16, with: newValue.rawValue)
        }
      }

      /// The IPv4 address of the intended receiver of the packet.
      public var destinationAddress: IPv4Address {
        get {
          IPv4Address(_storage.subdata(in: 16..<20))!
        }
        set {
          _storage.replaceSubrange(16..<20, with: newValue.rawValue)
        }
      }

      /// Internet protocol options.
      public var options: Data? {
        get {
          guard internetHeaderLength > 5 else {
            return nil
          }
          return _storage.subdata(in: 20..<internetHeaderLength * 4)
        }
        set {
          guard let newValue else {
            if internetHeaderLength > 5 {
              totalLength -= (internetHeaderLength - 5) * 4
              internetHeaderLength = 5
            }
            return
          }
          precondition(newValue.count % 4 == 0)
          _storage.insert(contentsOf: newValue, at: 20)
          internetHeaderLength += newValue.count / 4
          totalLength += newValue.count
        }
      }

      /// Transport layer data.
      public var payload: Data {
        get {
          _storage.suffix(from: internetHeaderLength * 4)
        }
        set {
          _storage = _storage.prefix(upTo: internetHeaderLength * 4) + newValue
          totalLength = _storage.count
        }
      }

      /// The IPv4 source port of the sender of the packet.
      ///
      /// 0 will be returned if payload data is empty.
      public var sourcePort: Address.Port {
        get {
          payload.prefix(2).withUnsafeBytes {
            Address.Port(rawValue: $0.load(as: UInt16.self).bigEndian)
          }
        }
        set {
          var newValue = newValue.rawValue.bigEndian
          withUnsafeBytes(of: &newValue) {
            if _storage.count >= payload.startIndex + 2 {
              _storage.replaceSubrange(payload.startIndex..<payload.startIndex + 2, with: Data($0))
            } else if _storage.count == payload.startIndex {
              _storage.append(Data($0))
            }
          }
        }
      }

      /// The IPv4 source port of the sender of the packet.
      ///
      /// 0 will be returned if payload data is empty.
      public var destinationPort: Address.Port {
        get {
          guard payload.count >= payload.startIndex + 4 else {
            return .any
          }
          return payload.subdata(in: payload.startIndex + 2..<payload.startIndex + 4)
            .withUnsafeBytes {
              Address.Port(rawValue: $0.load(as: UInt16.self).bigEndian)
            }
        }
        set {
          var newValue = newValue.rawValue.bigEndian
          withUnsafeBytes(of: &newValue) {
            if _storage.count >= payload.startIndex + 4 {
              _storage.replaceSubrange(
                payload.startIndex + 2..<payload.startIndex + 4, with: Data($0))
            } else if _storage.count == payload.startIndex + 2 {
              _storage.append(Data($0))
            } else if _storage.count == payload.startIndex {
              _storage.append(Data([0, 0]) + Data($0))
            }
          }
        }
      }

      /// IP packet data.
      public var data: Data {
        var chksum = headerChecksum
        var data = _storage
        withUnsafeBytes(of: &chksum) {
          data.replaceSubrange(10..<12, with: Data($0))
        }
        return data
      }

      private var _storage: Data

      // A boolean value determine whether IP header checksum has modified.
      private var isModified = false

      init(data: Data) {
        assert(data.count >= 20)
        self._storage = data
      }

      func chksum(_ data: Data, length: Int) -> UInt16 {
        guard data.count >= 20 else { return 0 }  // IPv4 header must be at least 20 bytes

        var sum: UInt32 = 0
        let length = data.count

        // Sum all 16-bit words
        var i = 0
        while i < length - 1 {
          let part = UInt32(_storage[i]) << 8 | UInt32(_storage[i + 1])
          sum += part
          i += 2
        }

        // If odd length, add the last byte
        if length % 2 != 0 {
          sum += UInt32(_storage[length - 1]) << 8
        }

        // Add carry bits
        while (sum >> 16) > 0 {
          sum = (sum & 0xFFFF) + (sum >> 16)
        }

        // One's complement
        let checksum = ~UInt16(sum & 0xFFFF)
        return checksum == 0 ? 0xFFFF : checksum  // Return 0xFFFF for 0
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
            "headerChecksum": headerChecksum,
            "sourceAddress": sourceAddress,
            "destinationAddress": destinationAddress,
            "options": options,
            "payload": payload,
            "sourcePort": sourcePort,
            "destinationPort": destinationPort,
            "data": data,
          ],
          displayStyle: .struct,
          ancestorRepresentation: .suppressed
        )
      }
    }

    case v4(IPv4Packet)

    /// The data content of the packet.
    public var data: Data {
      switch self {
      case .v4(let packet):
        return packet.data
      }
    }

    /// The protocol family of the packet (such as AF_INET or AF_INET6).
    public var protocolFamily: sa_family_t {
      switch self {
      case .v4(let packet):
        return packet.protocolFamily
      }
    }

    /// Initializes a new IP packet object with data and protocol family.
    /// - Parameters:
    ///   - data: The content of the packet.
    ///   - protocolFamily: The protocol family of the packet (such as AF_INET or AF_INET6).
    public init(data: Data, protocolFamily: sa_family_t) {
      assert(protocolFamily == PF_INET)
      self = .v4(.init(data: data))
    }

    func chksum(_ data: Data, length: Int) -> UInt16 {
      switch self {
      case .v4(let inet):
        return inet.chksum(data, length: length)
      }
    }
  }
#endif
