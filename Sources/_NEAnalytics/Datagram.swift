//
// See LICENSE.txt for license information
//

#if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  #if canImport(FoundationEssentials)
    import FoundationEssentials
  #else
    import Foundation
  #endif

  struct Datagram: Hashable, Sendable {

    /// The sender's port.
    var sourcePort: UInt16 {
      get {
        data.subdata(in: 0..<2).withUnsafeBytes {
          $0.load(as: UInt16.self).bigEndian
        }
      }
      set {
        var newValue = newValue.bigEndian
        withUnsafeBytes(of: &newValue) {
          _data.replaceSubrange(0..<2, with: Data($0))
        }
      }
    }

    /// The receiver's port.
    var destinationPort: UInt16 {
      get {
        data.subdata(in: 2..<4).withUnsafeBytes {
          $0.load(as: UInt16.self).bigEndian
        }
      }
      set {
        var newValue = newValue.bigEndian
        withUnsafeBytes(of: &newValue) {
          _data.replaceSubrange(2..<4, with: Data($0))
        }
      }
    }

    /// The length in bytes of the UDP datagram
    var length: Int {
      get {
        data.subdata(in: 4..<6).withUnsafeBytes {
          Int($0.load(as: UInt16.self).bigEndian)
        }
      }
      set {
        assert(newValue >= 8)
        assert(newValue <= UInt16.max)
        var newValue = newValue.bigEndian
        withUnsafeBytes(of: &newValue) {
          _data.replaceSubrange(4..<6, with: Data($0))
        }
      }
    }

    /// The checksum field may be used for error-checking of the header and data. This field is optional in IPv4, and mandatory in most
    /// cases in IPv6.
    var checksum: UInt16 {
      get {
        data.subdata(in: 6..<8).withUnsafeBytes {
          $0.load(as: UInt16.self).bigEndian
        }
      }
      set {
        assert(newValue >= 8)
        assert(newValue <= UInt16.max)
        var newValue = newValue.bigEndian
        withUnsafeBytes(of: &newValue) {
          _data.replaceSubrange(6..<8, with: Data($0))
        }
      }
    }

    /// The payload of the UDP packet.
    var payload: Data {
      get {
        data.suffix(from: 8)
      }
      set {
        _data = _data.prefix(upTo: 8) + newValue
        length = _data.count > UInt16.max ? 0 : _data.count
      }
    }

    var data: Data {
      _data
    }
    private var _data: Data

    init(data: Data) {
      _data = data
    }
  }
#endif
