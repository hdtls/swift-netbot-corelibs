//
// See LICENSE.txt for license information
//

import NIOCore

/// An `NEPacket` object represents the data, protocol family associated with an IP packet.
public struct NEPacket: Hashable, Sendable {

  public typealias Data = ByteBuffer

  /// The protocol family of the packet (such as AF_INET or AF_INET6).
  public var protocolFamily: NIOBSDSocket.AddressFamily {
    switch headerFields {
    case .v4(let fields): return fields.protocolFamily
    case .v6: return .inet6
    }
  }

  /// The packet headers.
  public var headerFields: NEIPFields

  /// The data content of the next layer packet data.
  public var payload: Data {
    switch self._storage[self._storage.startIndex] >> 4 {
    case 4:
      let internetHeaderLength = self._storage[self._storage.startIndex] & 0b0000_1111
      let startIndex = data.index(data.startIndex, offsetBy: Int(internetHeaderLength) * 4)
      return data.suffix(from: startIndex)
    default:
      assertionFailure("operationUnsupported")
      return Data()
    }
  }

  /// The data content of the packet.
  public var data: Data {
    guard self.headerFields.hasModified else {
      return _storage
    }
    return self.headerFields.data
  }

  private var _storage: Data

  /// Initializes a new IP packet object with data and protocol family.
  /// - Parameters:
  ///   - data: The content of the packet.
  ///   - protocolFamily: The protocol family of the packet (such as AF_INET or AF_INET6).
  public init?(data: Data, protocolFamily: NIOBSDSocket.AddressFamily) {
    guard let headerFields = NEIPFields(storage: data) else {
      return nil
    }
    self.headerFields = headerFields
    self._storage = data
  }
}
