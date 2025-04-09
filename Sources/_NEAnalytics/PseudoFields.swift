//
// See LICENSE.txt for license information
//

#if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  import NEAddressProcessing
  import NIOCore

  /// Pseudo fields for datagram.
  struct PseudoFields: Hashable, Sendable {

    /// The IPv4 address of the sender of the packet.
    var sourceAddress: IPv4Address

    /// The IPv4 address of the intended receiver of the packet.
    var destinationAddress: IPv4Address

    var zero = UInt8.zero

    /// Protocol used in the data portion of the IP datagram.
    var `protocol`: NIOIPProtocol

    /// Length of datagram data.
    var dataLength: UInt16
  }
#endif
