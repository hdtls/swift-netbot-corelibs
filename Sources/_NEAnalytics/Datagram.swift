//
// See LICENSE.txt for license information
//

#if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  import NIOCore

  struct Datagram: Hashable, Sendable {

    typealias Data = ByteBuffer

    /// The sender's port.
    var sourcePort: UInt16 {
      get {
        _storage.getInteger(at: _storage.readerIndex)!
      }
      set {
        _storage.setInteger(newValue, at: _storage.readerIndex)
      }
    }

    /// The receiver's port.
    var destinationPort: UInt16 {
      get {
        let position = _storage.index(_storage.readerIndex, offsetBy: MemoryLayout<UInt16>.size)
        return _storage.getInteger(at: position)!
      }
      set {
        let position = _storage.index(_storage.readerIndex, offsetBy: MemoryLayout<UInt16>.size)
        _storage.setInteger(newValue, at: position)
      }
    }

    /// The length in bytes of the UDP datagram, including header and payload.
    var totalLength: UInt16 {
      get {
        let position = _storage.index(_storage.readerIndex, offsetBy: MemoryLayout<UInt16>.size * 2)
        return _storage.getInteger(at: position, as: UInt16.self)!
      }
      set {
        let position = _storage.index(_storage.readerIndex, offsetBy: MemoryLayout<UInt16>.size * 2)
        _storage.setInteger(newValue, at: position)
      }
    }

    /// The checksum field may be used for error-checking of the header and data.
    /// This field is optional in IPv4, and mandatory in most cases in IPv6.
    var chksum: UInt16 {
      _chksum(data, pseudoFields: pseudoFields, zeroization: true)
    }

    /// The payload of the UDP packet.
    var payload: Data? {
      get {
        return data[8...]
      }
      set {
        if let newValue {
          _storage.replaceSubrange(8..., with: newValue)
        } else {
          _storage.removeSubrange(8...)
        }
        totalLength = UInt16(truncatingIfNeeded: _storage.count)
      }
    }

    /// Datagram data.
    var data: Data {
      var data = _storage
      data.setInteger(chksum, at: data.index(data.startIndex, offsetBy: 6))
      return data
    }

    /// Pseudo fields for chksum calculation, including fields from IP headers.
    var pseudoFields: PseudoFields

    private var _storage: Data

    init(data: Data, pseudoFields: PseudoFields) {
      assert(data.count >= MemoryLayout<UInt16>.size * 4)
      _storage = data
      self.pseudoFields = pseudoFields
    }
  }
#endif
