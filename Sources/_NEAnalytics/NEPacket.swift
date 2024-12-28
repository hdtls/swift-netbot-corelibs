//
// See LICENSE.txt for license information
//

#if canImport(Darwin) && ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  import CNELwIP
  import Foundation
  import Network

  enum _NEPacket: Hashable, Sendable {

    /// The class to process and build IP packet.
    struct Internet: Hashable, @unchecked Sendable {

      final private class _Storage: Hashable {

        var data: Data
        var protocolFamily: sa_family_t

        init(data: Data, protocolFamily: sa_family_t) {
          self.data = data
          self.protocolFamily = protocolFamily
        }

        func copy() -> _Storage {
          _Storage(data: data, protocolFamily: protocolFamily)
        }

        static func == (lhs: _Storage, rhs: _Storage) -> Bool {
          lhs.data == rhs.data && lhs.protocolFamily == rhs.protocolFamily
        }

        func hash(into hasher: inout Hasher) {
          hasher.combine(data)
          hasher.combine(protocolFamily)
        }
      }

      private var _storage: _Storage

      /// The IP protocol family` PF_INET` and `PF_INET6`.
      var protocolFamily: sa_family_t {
        _storage.protocolFamily
      }

      /// The IPv4 header is variable in size due to the optional 14th field (Options). The IHL field contains the size of the IPv4 header;
      /// it has 4 bits that specify the number of 32-bit words in the header.
      ///
      /// The minimum value for this field is 5, which indicates a length of 5 × 32 bits = 160 bits = 20 bytes. As a 4-bit field, the
      /// maximum value is 15; this means that the maximum size of the IPv4 header is 15 × 32 bits = 480 bits = 60 bytes.
      var internetHeaderLength: Int {
        get { Int(_storage.data[0] & 0b00001111) }
        set {
          assert(newValue <= 15)
          assert(newValue >= 5)
          copyStorageIfNotUniquelyReferenced()
          let newValue = _storage.data[0] & 0b11110000 | UInt8(newValue)
          _storage.data.replaceSubrange(0..<1, with: Data([newValue]))
        }
      }

      /// DSCP originally defined as the type of service (ToS), this field specifies differentiated services (DiffServ).
      var differentiatedServicesCodePoint: UInt8 {
        get { _storage.data[1] >> 2 }
        set {
          copyStorageIfNotUniquelyReferenced()
          let newValue = (newValue << 2) | (_storage.data[1] & 0b00000011)
          _storage.data.replaceSubrange(1..<2, with: Data([newValue]))
        }
      }

      /// This field allows end-to-end notification of network congestion without dropping packets.
      /// ECN is an optional feature available when both endpoints support it and effective when also supported by the underlying network.
      var explicitCongestionNotification: UInt8 {
        get { _storage.data[1] & 0b00000011 }
        set {
          copyStorageIfNotUniquelyReferenced()
          let newValue = (newValue & 0b00000011) | (_storage.data[1] & 0b11111100)
          _storage.data.replaceSubrange(1..<2, with: Data([newValue]))
        }
      }

      /// This 16-bit field defines the entire packet size in bytes, including header and data.
      var totalLength: Int {
        get {
          _storage.data.subdata(in: 2..<4).withUnsafeBytes {
            Int($0.load(as: UInt16.self).bigEndian)
          }
        }
        set {
          assert(newValue <= UInt16.max)
          assert(newValue >= 20)
          assert(newValue >= internetHeaderLength)
          copyStorageIfNotUniquelyReferenced()
          var newValue = UInt16(newValue).bigEndian
          withUnsafeBytes(of: &newValue) {
            _storage.data.replaceSubrange(2..<4, with: Data($0))
          }
        }
      }

      /// Identification field and is primarily used for uniquely identifying the group of fragments of a single IP datagram.
      var identification: UInt16 {
        get {
          _storage.data.subdata(in: 4..<6).withUnsafeBytes {
            $0.load(as: UInt16.self).bigEndian
          }
        }
        set {
          var newValue = newValue.bigEndian
          copyStorageIfNotUniquelyReferenced()
          withUnsafeBytes(of: &newValue) {
            _storage.data.replaceSubrange(4..<6, with: Data($0))
          }
        }
      }

      /// There are three flags defined within this field, R, DF and MF.
      var flags: UInt8 {
        get { _storage.data[6] >> 5 }
        set {
          copyStorageIfNotUniquelyReferenced()
          let newValue = (newValue << 5) | (_storage.data[6] & 0b00011111)
          _storage.data.replaceSubrange(6..<7, with: Data([newValue]))
        }
      }

      ///  the offset of a particular fragment relative to the beginning of the original unfragmented IP datagram.
      var fragmentOffset: Int {
        get {
          _storage.data.subdata(in: 6..<8).withUnsafeBytes {
            Int($0.load(as: UInt16.self).bigEndian & 0x1FFF)
          }
        }
        set {
          assert(newValue <= 0x1FFF)
          copyStorageIfNotUniquelyReferenced()
          var newValue = ((UInt16(flags) << 13) | UInt16(newValue)).bigEndian
          withUnsafeBytes(of: &newValue) {
            _storage.data.replaceSubrange(6..<8, with: Data($0))
          }
        }
      }

      /// The datagram's lifetime to prevent network failure in the event of a routing loop.
      var timeToLive: Int {
        get { Int(_storage.data[8]) }
        set {
          assert(newValue <= UInt8.max)
          copyStorageIfNotUniquelyReferenced()
          _storage.data.replaceSubrange(8..<9, with: Data([UInt8(newValue)]))
        }
      }

      /// The transport layer protocol used in the data portion of the IP datagram.
      var transportLayerProtocol: TransportLayerProtocol {
        get { TransportLayerProtocol(rawValue: _storage.data[9]) }
        set {
          copyStorageIfNotUniquelyReferenced()
          _storage.data.replaceSubrange(9..<10, with: Data([newValue.rawValue]))
        }
      }

      /// The IPv4 header checksum used for error checking of the header.
      var headerChecksum: UInt16 {
        _storage.data.replaceSubrange(10..<12, with: Data([0, 0]))
        return chksum(_storage.data, length: internetHeaderLength * 4)
      }

      /// The IPv4 address of the sender of the packet.
      var sourceAddress: IPv4Address {
        get {
          IPv4Address(_storage.data.subdata(in: 12..<16), nil)!
        }
        set {
          copyStorageIfNotUniquelyReferenced()
          _storage.data.replaceSubrange(12..<16, with: newValue.rawValue)
        }
      }

      /// The IPv4 address of the intended receiver of the packet.
      var destinationAddress: IPv4Address {
        get {
          IPv4Address(_storage.data.subdata(in: 16..<20), nil)!
        }
        set {
          copyStorageIfNotUniquelyReferenced()
          _storage.data.replaceSubrange(16..<20, with: newValue.rawValue)
        }
      }

      /// Internet protocol options.
      var options: Data? {
        get {
          guard internetHeaderLength > 5 else {
            return nil
          }
          return _storage.data.subdata(in: 20..<internetHeaderLength * 4)
        }
        set {
          guard let newValue else {
            if internetHeaderLength > 5 {
              totalLength -= (internetHeaderLength - 5) * 4
              internetHeaderLength = 5
            }
            return
          }
          assert(newValue.count % 4 == 0)
          copyStorageIfNotUniquelyReferenced()
          _storage.data.insert(contentsOf: newValue, at: 20)
          internetHeaderLength += newValue.count / 4
          totalLength += newValue.count
        }
      }

      /// Transport layer data.
      var payload: Data {
        get {
          _storage.data.suffix(from: internetHeaderLength * 4)
        }
        set {
          copyStorageIfNotUniquelyReferenced()
          _storage.data = _storage.data.prefix(upTo: internetHeaderLength * 4) + newValue
          totalLength = _storage.data.count
        }
      }

      /// IP packet data.
      var data: Data {
        var sum = headerChecksum
        withUnsafeBytes(of: &sum) {
          _storage.data.replaceSubrange(10..<12, with: Data($0))
        }
        return _storage.data
      }

      init(data: Data, protocolFamily: sa_family_t) {
        assert(data.count >= 20)
        self._storage = _Storage(data: data, protocolFamily: protocolFamily)
      }

      private mutating func copyStorageIfNotUniquelyReferenced() {
        if !isKnownUniquelyReferenced(&self._storage) {
          self._storage = self._storage.copy()
        }
      }

      func chksum(_ data: Data, length: Int) -> UInt16 {
        return data.withUnsafeBytes {
          inet_chksum($0.baseAddress, u16_t(min(data.count, length)))
        }
      }
    }

    case v4(Internet)

    var transportLayerProtocol: TransportLayerProtocol {
      switch self {
      case .v4(let packet):
        return packet.transportLayerProtocol
      }
    }

    init(data: Data, protocolFamily: sa_family_t) {
      assert(protocolFamily == PF_INET)
      self = .v4(.init(data: data, protocolFamily: protocolFamily))
    }

    func chksum(_ data: Data, length: Int) -> UInt16 {
      switch self {
      case .v4(let inet):
        return inet.chksum(data, length: length)
      }
    }
  }
#endif
