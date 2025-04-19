//
// See LICENSE.txt for license information
//

import NIOCore

public struct Datagram: Hashable, Sendable {

  public typealias Data = ByteBuffer

  /// The sender's port.
  public var sourcePort: UInt16 {
    get {
      _storage.getInteger(at: _storage.readerIndex)!
    }
    set {
      _storage.setInteger(newValue, at: _storage.readerIndex)
    }
  }

  /// The receiver's port.
  public var destinationPort: UInt16 {
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
  public var totalLength: UInt16 {
    _totalLength
  }
  private var _totalLength: UInt16 {
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
  public var chksum: UInt16 {
    _chksum(_storage, pseudoFields: pseudoFields, zeroization: true)
  }

  /// The payload of the UDP packet.
  public var payload: Data? {
    get {
      let startIndex = _storage.index(_storage.startIndex, offsetBy: MemoryLayout<UInt16>.size * 4)
      return _storage[startIndex...]
    }
    set {
      let startIndex = _storage.index(_storage.startIndex, offsetBy: MemoryLayout<UInt16>.size * 4)
      if let newValue {
        _storage.replaceSubrange(startIndex..., with: newValue)
      } else {
        _storage.removeSubrange(startIndex...)
      }
      _totalLength = UInt16(truncatingIfNeeded: _storage.count)
      pseudoFields.dataLength = totalLength
    }
  }

  /// Datagram data.
  public var data: Data {
    var data = _storage
    data.setInteger(chksum, at: data.index(data.startIndex, offsetBy: 6))
    return data
  }

  /// Pseudo fields for chksum calculation, including fields from IP headers.
  public var pseudoFields: PseudoFields

  private var _storage: Data

  public init(data: Data, pseudoFields: PseudoFields) {
    _storage = data
    self.pseudoFields = pseudoFields
    assert(data.count >= MemoryLayout<UInt16>.size * 4)
    assert(totalLength == (payload?.count ?? 0) + MemoryLayout<UInt16>.size * 4)
  }

  init(pseudoFields: PseudoFields) {
    self._storage = Data(repeating: .zero, count: MemoryLayout<UInt16>.size * 4)
    self.pseudoFields = pseudoFields
    self._totalLength = UInt16(MemoryLayout<UInt16>.size * 4)
  }
}
