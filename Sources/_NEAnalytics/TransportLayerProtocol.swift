//
// See LICENSE.txt for license information
//

#if ENABLE_EXPERIMENTAL_FEATURE_PACKET_PROCESSING
  /// Common transport layer protocol identifiers.
  struct TransportLayerProtocol: RawRepresentable, Hashable, Sendable {

    var rawValue: UInt8

    init(rawValue: RawValue) {
      self.rawValue = rawValue
    }

    /// Internet Control Message Protocol
    static let icmp = TransportLayerProtocol(rawValue: 1)

    /// Internet Group Management Protocol
    static let igmp = TransportLayerProtocol(rawValue: 2)

    /// Transmission Control Protocol
    static let tcp = TransportLayerProtocol(rawValue: 6)

    /// User Datagram Protocol
    static let udp = TransportLayerProtocol(rawValue: 17)

    /// Datagram Congestion Control Protocol
    static let dccp = TransportLayerProtocol(rawValue: 33)

    /// IPv6 encapsulation
    static let encap = TransportLayerProtocol(rawValue: 41)

    /// Resource Reservation Protocol
    static let rsvp = TransportLayerProtocol(rawValue: 46)

    /// Encapsulating Security Payload
    static let esp = TransportLayerProtocol(rawValue: 50)

    /// Authentication Header
    static let ah = TransportLayerProtocol(rawValue: 51)

    /// Open Shortest Path First
    static let ospf = TransportLayerProtocol(rawValue: 89)

    /// Stream Control Transmission Protocol
    static let sctp = TransportLayerProtocol(rawValue: 132)
  }
#endif
