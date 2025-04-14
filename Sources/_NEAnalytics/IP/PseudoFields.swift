//
// See LICENSE.txt for license information
//

import NEAddressProcessing
import NIOCore

/// Pseudo fields for datagram.
public struct PseudoFields: Hashable, Sendable {

  /// The IPv4 address of the sender of the packet.
  public var sourceAddress: IPv4Address

  /// The IPv4 address of the intended receiver of the packet.
  public var destinationAddress: IPv4Address

  public var zero = UInt8.zero

  /// Protocol used in the data portion of the IP datagram.
  public var `protocol`: NIOIPProtocol

  /// Length of datagram data.
  public var dataLength: UInt16
}
