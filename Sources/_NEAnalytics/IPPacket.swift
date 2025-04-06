//
// See LICENSE.txt for license information
//

#if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  public import NEAddressProcessing
  public import NIOCore
  private import CNELwIP

  /// An `IPPacket` object represents the data, protocol family associated with an IP packet.
  public enum IPPacket: Hashable, Sendable {

    /// The class to process and build IPv4 packet.
    public struct IPv4Packet: Hashable, CustomReflectable, Sendable {

      /// The IP protocol family` AF_INET`.
      public var protocolFamily: UInt8 { 4 }

      /// The IPv4 header is variable in size due to the optional 14th field (Options). The IHL field contains the size of the IPv4 header;
      /// it has 4 bits that specify the number of 32-bit words in the header.
      ///
      /// The minimum value for this field is 5, which indicates a length of 5 × 32 bits = 160 bits = 20 bytes. As a 4-bit field, the
      /// maximum value is 15; this means that the maximum size of the IPv4 header is 15 × 32 bits = 480 bits = 60 bytes.
      public var internetHeaderLength: Int {
        get {
          let position = _storage.readerIndex
          return Int(_storage.getInteger(at: position, as: UInt8.self)! & 0b0000_1111)
        }
        set {
          precondition(newValue <= 15)
          precondition(newValue >= 5)
          let position = _storage.readerIndex
          let newValue = _storage.getInteger(at: position)! & 0b1111_0000 | UInt8(newValue)
          _storage.setInteger(newValue, at: position)
        }
      }

      /// DSCP originally defined as the type of service (ToS), this field specifies differentiated services (DiffServ).
      public var differentiatedServicesCodePoint: UInt8 {
        get {
          let position = _storage.readerIndex.advanced(by: 1)
          return (_storage.getInteger(at: position)! >> 2) & 0b0011_1111
        }
        set {
          let position = _storage.readerIndex.advanced(by: 1)
          // Ensure DSCP is valid (6-bit value)
          let validatedDSCP = min(newValue, 0x3F)
          _storage.setInteger((validatedDSCP << 2) | explicitCongestionNotification, at: position)
        }
      }

      /// This field allows end-to-end notification of network congestion without dropping packets.
      /// ECN is an optional feature available when both endpoints support it and effective when also supported by the underlying network.
      public var explicitCongestionNotification: UInt8 {
        get {
          let position = _storage.readerIndex.advanced(by: 1)
          return _storage.getInteger(at: position)! & 0b0000_0011
        }
        set {
          let position = _storage.readerIndex.advanced(by: 1)
          let validatedECN = min(newValue, 0b000_0011)
          var dscpAndECN = _storage.getInteger(at: position, as: UInt8.self)!
          // Clear ECN and set new value
          dscpAndECN &= 0xFC
          dscpAndECN |= validatedECN
          _storage.setInteger(dscpAndECN, at: position)
        }
      }

      /// This 16-bit field defines the entire packet size in bytes, including header and data.
      public var totalLength: Int {
        get {
          let position = _storage.readerIndex.advanced(by: 2)
          return Int(_storage.getInteger(at: position, as: UInt16.self)!)
        }
        set {
          precondition(newValue <= UInt16.max)
          precondition(newValue >= 20)
          precondition(newValue >= internetHeaderLength)
          let position = _storage.readerIndex.advanced(by: 2)
          _storage.setInteger(UInt16(newValue), at: position)
        }
      }

      /// Identification field and is primarily used for uniquely identifying the group of fragments of a single IP datagram.
      public var identification: UInt16 {
        get {
          let position = _storage.readerIndex.advanced(by: 4)
          return _storage.getInteger(at: position)!
        }
        set {
          let position = _storage.readerIndex.advanced(by: 4)
          _storage.setInteger(newValue, at: position)
        }
      }

      /// There are three flags defined within this field, R, DF and MF.
      public var flags: UInt8 {
        get {
          let position = _storage.readerIndex.advanced(by: 6)
          let flagsAndFragmentOffset = _storage.getInteger(at: position, as: UInt16.self)!
          return UInt8((flagsAndFragmentOffset >> 13) & 0x7)
        }
        set {
          let position = _storage.readerIndex.advanced(by: 6)
          let flags = UInt16(newValue) << 13
          _storage.setInteger(flags | fragmentOffset, at: position)
        }
      }

      ///  the offset of a particular fragment relative to the beginning of the original unfragmented IP datagram.
      public var fragmentOffset: UInt16 {
        get {
          let position = _storage.readerIndex.advanced(by: 6)
          let flagsAndFragmentOffset = _storage.getInteger(at: position, as: UInt16.self)!
          return flagsAndFragmentOffset & 0x1FFF
        }
        set {
          let position = _storage.readerIndex.advanced(by: 6)
          let flags = UInt16(flags) << 13
          let validatedOffset = min(newValue, 0x1FFF)
          _storage.setInteger(flags | validatedOffset, at: position)
        }
      }

      /// The datagram's lifetime to prevent network failure in the event of a routing loop.
      public var timeToLive: Int {
        get {
          let position = _storage.readerIndex.advanced(by: 8)
          return Int(_storage.getInteger(at: position, as: UInt8.self)!)
        }
        set {
          let position = _storage.readerIndex.advanced(by: 8)
          _storage.setInteger(UInt8(newValue), at: position)
        }
      }

      /// Protocol used in the data portion of the IP datagram.
      public var `protocol`: NIOIPProtocol {
        get {
          let position = _storage.readerIndex.advanced(by: 9)
          return NIOIPProtocol(rawValue: _storage.getInteger(at: position)!)
        }
        set {
          let position = _storage.readerIndex.advanced(by: 9)
          _storage.setInteger(newValue.rawValue, at: position)
        }
      }

      /// The IPv4 header checksum used for error checking of the header.
      public var headerChecksum: UInt16 {
        var data = _storage
        data.setInteger(UInt16.zero, at: data.readerIndex.advanced(by: 10))
        return chksum(data, length: internetHeaderLength * 4)
      }

      /// The IPv4 address of the sender of the packet.
      public var sourceAddress: IPv4Address {
        get {
          let position = _storage.readerIndex.advanced(by: 12)
          return IPv4Address(.init(_storage.getBytes(at: position, length: 4)!))!
        }
        set {
          let position = _storage.readerIndex.advanced(by: 12)
          _storage.setBytes(newValue.rawValue, at: position)
        }
      }

      /// The IPv4 address of the intended receiver of the packet.
      public var destinationAddress: IPv4Address {
        get {
          let position = _storage.readerIndex.advanced(by: 16)
          return IPv4Address(.init(_storage.getBytes(at: position, length: 4)!))!
        }
        set {
          let position = _storage.readerIndex.advanced(by: 16)
          _storage.setBytes(newValue.rawValue, at: position)
        }
      }

      /// Internet protocol options.
      public var options: ByteBuffer? {
        get {
          guard internetHeaderLength > 5 else {
            return nil
          }
          let position = _storage.readerIndex.advanced(by: 20)
          let length = internetHeaderLength * 4 - 20
          return _storage.getSlice(at: position, length: length)
        }
        set {
          // Payload deponds on internetHeaderLength, after options data changed,
          // internetHeaderLength should also be changed, so we need a require payload before we
          // make any changes of IP header.
          let payload = payload
          var bytesToWrite: ByteBuffer?

          if let newValue {
            bytesToWrite = newValue

            // IHL is always a multiple of 4, so if new options data count is not multiple of 4
            // we need fill zero to make it a multiple of 4.
            if newValue.readableBytes % 4 != 0 {
              let bytesNeeded = 4 - newValue.readableBytes % 4
              bytesToWrite?.writeBytes(Array(repeating: UInt8.zero, count: bytesNeeded))
            }
          }

          if let bytesToWrite {
            internetHeaderLength = (20 + bytesToWrite.readableBytes) / 4
          } else {
            internetHeaderLength = 5
          }

          if let payload = payload {
            bytesToWrite.setOrWriteImmutableBuffer(payload)
          }

          _storage.moveWriterIndex(to: _storage.readerIndex.advanced(by: 20))
          if let bytesToWrite {
            _storage.writeImmutableBuffer(bytesToWrite)
          }

          totalLength = _storage.readableBytes
        }
      }

      /// Transport layer data.
      public var payload: ByteBuffer? {
        get {
          let l = internetHeaderLength * 4
          guard _storage.readableBytes > l else {
            return nil
          }
          return
            _storage
            .getSlice(
              at: _storage.readerIndex.advanced(by: l),
              length: _storage.readableBytes - l
            )
        }
        set {
          _storage.moveWriterIndex(to: _storage.readerIndex.advanced(by: internetHeaderLength * 4))
          if let newValue {
            _storage.writeImmutableBuffer(newValue)
          }
          totalLength = _storage.readableBytes
        }
      }

      /// IP packet data.
      public var data: ByteBuffer {
        var data = _storage
        data.setInteger(headerChecksum, at: data.readerIndex.advanced(by: 10), endianness: .little)
        return data
      }

      private var _storage: ByteBuffer

      init(data: ByteBuffer) {
        self._storage = data

        // Ensure we have at least 20 bytes.
        let bytesNeeded = 20 - data.readableBytes
        if bytesNeeded > 0 {
          self._storage.writeRepeatingByte(0, count: bytesNeeded)
        }
      }

      func chksum(_ data: ByteBuffer, length: Int) -> UInt16 {
        data.withUnsafeReadableBytes {
          inet_chksum($0.baseAddress, UInt16(length))
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
            "headerChecksum": headerChecksum,
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

    case v4(IPv4Packet)

    /// The data content of the packet.
    public var data: ByteBuffer {
      switch self {
      case .v4(let packet):
        return packet.data
      }
    }

    /// The protocol family of the packet (such as AF_INET or AF_INET6).
    public var protocolFamily: UInt8 {
      switch self {
      case .v4(let packet):
        return packet.protocolFamily
      }
    }

    /// Initializes a new IP packet object with data and protocol family.
    /// - Parameters:
    ///   - data: The content of the packet.
    ///   - protocolFamily: The protocol family of the packet (such as AF_INET or AF_INET6).
    public init(data: ByteBuffer, protocolFamily: UInt8) {
      assert(protocolFamily == 4)
      self = .v4(.init(data: data))
    }
  }
#endif
