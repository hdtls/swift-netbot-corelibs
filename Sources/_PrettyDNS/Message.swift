//
// See LICENSE.txt for license information
//

import NEAddressProcessing
import NIOCore

/// `QTYPE` fields appear in the question part of a query, define the type of the question.
@DebugDescription public struct QTYPE: RawRepresentable, Hashable, Sendable {

  public var rawValue: UInt16

  public init(rawValue: UInt16) {
    self.rawValue = rawValue
  }
}

/// Full list of DNS Parameters can be found here:  https://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml
extension QTYPE {

  /// A IPv4 host address.
  public static let a = QTYPE(rawValue: 1)

  /// An authoritative name server.
  public static let ns = QTYPE(rawValue: 2)

  /// A mail destination.
  ///
  /// - Important: Obsoleted - use `.mx` instead.
  public static let md = QTYPE(rawValue: 3)

  /// A mail forwarder.
  ///
  /// - Important: Obsoleted - use `.mx` instead.
  public static let mf = QTYPE(rawValue: 4)

  /// The canonical name for an alias.
  public static let cname = QTYPE(rawValue: 5)

  /// Marks the start of a zone of authority.
  public static let soa = QTYPE(rawValue: 6)

  /// A mailbox domain name.
  ///
  /// - Important: EXPERIMENTAL.
  public static let mb = QTYPE(rawValue: 7)

  /// A mail group member.
  ///
  /// - Important: EXPERIMENTAL.
  public static let mg = QTYPE(rawValue: 8)

  /// A mail rename domain name.
  ///
  /// - Important: EXPERIMENTAL.
  public static let mr = QTYPE(rawValue: 9)

  /// A null RR.
  ///
  /// - Important: EXPERIMENTAL.
  public static let null = QTYPE(rawValue: 10)

  /// A well-known service description.
  public static let wks = QTYPE(rawValue: 11)

  /// A domain name pointer (reverse DNS).
  public static let ptr = QTYPE(rawValue: 12)

  /// Host information.
  public static let hinfo = QTYPE(rawValue: 13)

  /// Mailbox or mail list information.
  public static let minfo = QTYPE(rawValue: 14)

  /// Mail exchange.
  public static let mx = QTYPE(rawValue: 15)

  /// Text strings.
  public static let txt = QTYPE(rawValue: 16)

  /// A IPv6 host address.
  public static let aaaa = QTYPE(rawValue: 28)

  /// Service locator.
  public static let srv = QTYPE(rawValue: 33)

  /// Naming Authority Pointer.
  public static let naptr = QTYPE(rawValue: 35)

  /// EDNS pseudo.
  public static let opt = QTYPE(rawValue: 41)

  /// Delegation signer.
  public static let ds = QTYPE(rawValue: 43)

  /// DNSSEC signature.
  public static let rrsig = QTYPE(rawValue: 46)

  /// Next secure.
  public static let nsec = QTYPE(rawValue: 47)

  /// Hashed NSEC.
  public static let nsec3 = QTYPE(rawValue: 50)

  /// NSEC3 parameters.
  public static let nsec3Param = QTYPE(rawValue: 51)

  /// TLS certificate association.
  public static let tlsa = QTYPE(rawValue: 52)

  /// S/MIME cert association.
  public static let smimea = QTYPE(rawValue: 53)

  /// PGP public key.
  public static let openPGPKey = QTYPE(rawValue: 61)

  /// Service binding.
  public static let svcb = QTYPE(rawValue: 64)

  /// HTTPS binding (SVCB).
  public static let https = QTYPE(rawValue: 65)

  /// Incremental zone transfer.
  public static let ixfr = QTYPE(rawValue: 251)

  /// Transfer of an entire zone.
  public static let axfr = QTYPE(rawValue: 252)

  /// Mailbox-related records (MB, MG or MR).
  public static let mailb = QTYPE(rawValue: 253)

  /// Mail agent RRs.
  ///
  /// - Important: obsolete - see .mx.
  public static let maila = QTYPE(rawValue: 254)

  /// A request for all records.
  public static let any = QTYPE(rawValue: 255)
}

extension QTYPE: CustomDebugStringConvertible {

  public var debugDescription: String {
    switch self {
    case .a: return "A"
    case .ns: return "NS"
    case .md: return "MD"
    case .mf: return "MF"
    case .cname: return "CNAME"
    case .soa: return "SOA"
    case .mb: return "MB"
    case .mg: return "MG"
    case .mr: return "MR"
    case .null: return "NULL"
    case .wks: return "WKS"
    case .ptr: return "PTR"
    case .hinfo: return "HINFO"
    case .minfo: return "MINFO"
    case .mx: return "MX"
    case .txt: return "TXT"
    case .aaaa: return "AAAA"
    case .srv: return "SRV"
    case .naptr: return "NAPTR"
    case .axfr: return "AXFR"
    case .opt: return "OPT"
    case .ds: return "DS"
    case .rrsig: return "RRSIG"
    case .nsec: return "NSEC"
    case .nsec3: return "NSEC3"
    case .nsec3Param: return "NSEC3PARAM"
    case .tlsa: return "TLSA"
    case .smimea: return "S/MIME cert association"
    case .openPGPKey: return "OPENPGPKEY"
    case .svcb: return "SVCB"
    case .https: return "HTTPS"
    case .ixfr: return "IXFR"
    case .mailb: return "MAILB"
    case .maila: return "MAILA"
    case .any: return "*"
    default: return "RAW(\(rawValue))"
    }
  }
}

/// `QCLASS` fields appear in the question section of a query, define the class of the question.
public struct QCLASS: RawRepresentable, Hashable, Sendable {

  public var rawValue: UInt16

  public init(rawValue: UInt16) {
    self.rawValue = rawValue
  }
}

extension QCLASS {

  /// The internet (IN).
  public static let internet: QCLASS = QCLASS(rawValue: 1)

  /// The CSNET class.
  ///
  /// - Important: Obsolete - used only for examples in some obsolete.
  public static let csnet = QCLASS(rawValue: 2)

  /// The CHAOS class (CH).
  public static let chaos = QCLASS(rawValue: 3)

  /// Hesiod (HS).
  public static let hesiod = QCLASS(rawValue: 4)

  /// QCLASS NONE.
  public static let none = QCLASS(rawValue: 254)

  /// QCLASS * (any).
  public static let any = QCLASS(rawValue: 255)
}

extension QCLASS: CustomDebugStringConvertible {

  public var debugDescription: String {
    switch self {
    case .internet: return "IN"
    case .csnet: return "CSNET"
    case .chaos: return "CH"
    case .hesiod: return "HS"
    case .none: return "QCLASS NONE"
    case .any: return "QCLASS * (Any)"
    default: return "RAW(\(rawValue))"
    }
  }
}

/// `TYPE` fields are used in resource records.
///
/// - note: These types should be a subset of QTYPEs, for convenience we use QTYPE directly.
public typealias TYPE = QTYPE

/// `CLASS` fields are used in resource records.
///
/// - note: These types should be a subset of QCLASSes, for convenience we use QCLASS directly,
public typealias CLASS = QCLASS

public enum RDATALength: Hashable, Sendable {
  case determined(UInt16)
  case flexible
}

/// Resource record defines information about a dns resource record,
/// including pertains domain name, type, class, ttl, data length and
/// data.
public protocol ResourceRecord: Hashable, Sendable {

  associatedtype Data

  /// A domain name to which this resource record pertains.
  var domainName: String { get }

  /// The time interval (in seconds) that the resource record may be
  /// cached before it should be discarded.  Zero values are
  /// interpreted to mean that the RR can only be used for the
  /// transaction in progress, and should not be cached.
  var ttl: Int32 { get }

  /// The meaning of the data in the `RDATA` field.
  var dataType: TYPE { get }

  /// The class of the data in the `RDATA` field.
  var dataClass: CLASS { get }

  /// The length in octets of the `RDATA` field.
  var dataLength: RDATALength { get }

  /// The content of the `RDATA` field. The format of this information
  /// varies according to the TYPE and CLASS of the resource record.
  ///
  /// For example, the if the TYPE is A and the CLASS is IN,
  /// the RDATA field is a Internet address (e.g., "10.2.0.52").
  var data: Data { get }
}

/// An A (Address) record maps a domain name to an IP address.
///
/// When someone types a domain name (like example.com) in their
/// browser, the DNS system uses the A record to translate that domain
/// into an IP address (like 192.0.2.1) so that it knows where to send the
/// request.
public struct ARecord: ResourceRecord {

  public typealias Data = IPv4Address

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE { .a }

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// NS record that specifies which servers are authoritative for a particular
/// domain. In simpler terms, it tells the internet where to look for the DNS
/// records for that domain.
public struct NSRecord: ResourceRecord {

  public typealias Data = String

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE { .ns }

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// A CNAME (Canonical Name) record is a type of DNS record used to
/// domain name to another.
///
/// Essentially, it allows you to point one domain (or subdomain) to another
/// domain, rather than directly mapping it to an IP address like with an A
/// record.
public struct CNAMERecord: ResourceRecord {

  public typealias Data = String

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE { .cname }

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// An SOA (Start of Authority) record is a type of DNS record that provides
/// information about the domain's DNS zone.
///
/// It marks the start of a zone and contains important details about the
/// domain's authoritative DNS server and various configuration parameters.
///
/// The SOA record is critical for DNS zone management because it helps
/// control how DNS information is propagated and cached across the
/// internet. It's usually the first record in a DNS zone file.
public struct SOARecord: ResourceRecord {

  /// `SOARecord.Data` defines authoritative information about a
  /// domain, including primary name server, administrator email, and
  /// domain settings like serial number and refresh intervals.
  public struct Data: Hashable, Sendable {

    /// Primary name server.
    public var primaryNameServer: String

    /// Mailbox of the person responsible for this zone.
    public var responsibleMailbox: String

    /// Serial number of the zone (used for version tracking).
    public var serialNumber: UInt32

    /// Refresh interval (how often secondary servers check for updates).
    public var refreshInterval: UInt32

    /// Retry interval (how long to wait before retrying a failed transfer).
    public var retryInterval: UInt32

    /// Expiration time (how long secondary servers should keep data if unreachable).
    public var expirationTime: UInt32

    /// Minimum TTL for negative caching.
    public var ttl: UInt32

    public init(
      primaryNameServer: String,
      responsibleMailbox: String,
      serialNumber: UInt32,
      refreshInterval: UInt32,
      retryInterval: UInt32,
      expirationTime: UInt32,
      ttl: UInt32
    ) {
      self.primaryNameServer = primaryNameServer
      self.responsibleMailbox = responsibleMailbox
      self.serialNumber = serialNumber
      self.refreshInterval = refreshInterval
      self.retryInterval = retryInterval
      self.expirationTime = expirationTime
      self.ttl = ttl
    }
  }

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE { .soa }

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// A PTR (Pointer) record is a type of DNS record used for reverse DNS lookups.
///
/// While an A or CNAME record resolves a domain name to an IP address, a
/// PTR record resolves an IP address back to a domain name.
///
/// It’s primarily used in reverse DNS lookups to determine the domain name
/// associated with an IP address.
public struct PTRRecord: ResourceRecord {

  public typealias Data = String

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE { .ptr }

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// An MX (Mail Exchange) record is a type of DNS record that specifies the
/// mail servers responsible for receiving email on behalf of a domain.
///
/// When someone sends an email to an address (e.g., user@example.com),
/// the MX record tells the sending email server where to deliver the email.
public struct MXRecord: ResourceRecord {

  /// `MXRecord.Data` define mail servers responsible for handling email
  /// for a domain. It includes a priority value to determine the order in which
  /// mail servers should be used.
  public struct Data: Hashable, Sendable {

    /// The priority of the mail server (lower values are preferred).
    public var preference: UInt16

    /// The mail server hostname.
    public var exchange: String

    public init(preference: UInt16, exchange: String) {
      self.preference = preference
      self.exchange = exchange
    }
  }

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE { .mx }

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// A TXT (Text) record is a type of DNS record that allows you to store
/// arbitrary text data in a domain's DNS zone.
///
/// While TXT records were originally designed for human-readable
/// information, they are now commonly used for a variety of purposes
/// related to domain verification and security.
public struct TXTRecord: ResourceRecord {

  public typealias Data = String

  public var domainName: String

  public var dataType: TYPE { .txt }

  public var dataClass: CLASS

  public var ttl: Int32

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// An AAAA record is a type of DNS record that maps a domain name
/// to an IPv6 address, just like the A record maps a domain to an IPv4
/// address.
///
/// While the A record works with the older IPv4 protocol (e.g., 192.0.2.1),
/// the AAAA record is used for the newer IPv6 protocol, which provides
/// a much larger address space and is becoming increasingly important
/// as the number of devices connected to the internet grows.
public struct AAAARecord: ResourceRecord {

  public typealias Data = IPv6Address

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE { .aaaa }

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// An SRV (Service) record is a type of DNS record used to define the
/// location (hostname and port) of servers for specific services. It
/// allows you to specify the server that provides a particular service
/// (e.g., SIP, XMPP, LDAP) and is commonly used for services like instant
/// messaging, VoIP, and other network protocols that require server
/// discovery.
public struct SRVRecord: ResourceRecord {

  public struct Data: Hashable, Sendable {

    /// The priority of the target host (lower values are preferred).
    public var priority: UInt16

    /// A relative weight for records with the same priority.
    public var weight: UInt16

    /// The port number of the service.
    public var port: UInt16

    /// The hostname of the machine providing the service.
    public var hostname: String

    public init(priority: UInt16, weight: UInt16, port: UInt16, hostname: String) {
      self.priority = priority
      self.weight = weight
      self.port = port
      self.hostname = hostname
    }
  }

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE { .srv }

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// A NAPTR (Naming Authority Pointer) record is a type of DNS record
/// used primarily for service discovery and protocol resolution.
/// It allows you to map domain names to other domain names, which
/// can then be used for various purposes, such as implementing services
/// like VoIP (Voice over IP), email, or even SIP (Session Initiation Protocol).
///
/// NAPTR records are part of the DNS-based service discovery (DNS-SD)
/// system, which helps resolve service names to specific protocols and
/// ports.
///
/// NAPTR records are often used in combination with SRV (Service) records,
/// particularly in systems like SIP and ENUM (E.164 Number Mapping).
public struct NAPTRRecord: ResourceRecord {

  public struct Data: Hashable, Sendable {

    /// The order of processing (lower values are processed first).
    public var order: UInt16

    /// Weight for processing entries with the same order.
    public var preference: UInt16

    /// Control string indicating action (e.g., "U" for URI rewrite).
    public var flags: String

    /// Service protocol identifier (e.g., "SIP+D2U").
    public var services: String

    /// A regular expression-based rewrite rule.
    public var regExp: String

    /// A domain name for further processing if Regexp is empty.
    public var replacement: String

    public init(
      order: UInt16,
      preference: UInt16,
      flags: String,
      services: String,
      regExp: String,
      replacement: String
    ) {
      self.order = order
      self.preference = preference
      self.flags = flags
      self.services = services
      self.regExp = regExp
      self.replacement = replacement
    }
  }

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE { .naptr }

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: Data

  public init(
    domainName: String,
    ttl: Int32,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// A RAW record is a type erased resource record.
public struct RAWRecord: ResourceRecord {

  public typealias Data = ByteBuffer

  public var domainName: String

  public var ttl: Int32

  public var dataType: TYPE

  public var dataClass: CLASS

  public var dataLength: RDATALength

  public var data: ByteBuffer

  public init(
    domainName: String,
    ttl: Int32,
    dataType: TYPE,
    dataClass: CLASS = .internet,
    dataLength: RDATALength = .flexible,
    data: Data
  ) {
    self.domainName = domainName
    self.ttl = ttl
    self.dataType = dataType
    self.dataClass = dataClass
    self.dataLength = dataLength
    self.data = data
  }
}

/// The question is used to carry the "question" in most DNS queries.
public struct Question: Hashable, Sendable {

  /// The domain name to query.
  public var domainName: String

  /// The type of the dns query.
  public var queryType: QTYPE

  /// The type of the dns query.
  public var queryClass: QCLASS

  public init(domainName: String, queryType: QTYPE, queryClass: QCLASS = .internet) {
    self.domainName = domainName
    self.queryType = queryType
    self.queryClass = queryClass
  }
}

/// All communications inside of the domain protocol are carried in a single
/// format called a message.  The top level format of message is divided
/// into 5 sections (some of which are empty in certain cases) shown below:
///
//  +---------------------+
//  |        Header       |
//  +---------------------+
//  |       Question      | the question for the name server
//  +---------------------+
//  |        Answer       | RRs answering the question
//  +---------------------+
//  |      Authority      | RRs pointing toward an authority
//  +---------------------+
//  |      Additional     | RRs holding additional information
//  +---------------------+
///
/// The header section is always present.
public struct Message: Sendable {

  /// The header includes fields that specify which of the remaining sections are
  /// present, and also specify whether the message is a query or a response, a
  /// standard query or some other opcode, etc. The format of header shown below:
  ///
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                      ID                       |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                    QDCOUNT                    |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                    ANCOUNT                    |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                    NSCOUNT                    |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  //  |                    ARCOUNT                    |
  //  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  /// For more information see [Header section format](https://datatracker.ietf.org/doc/html/rfc1035#section-4.1.1)
  ///
  public struct HeaderFields: Hashable, Sendable {

    public struct Flags: Hashable, Sendable, RawRepresentable, CustomReflectable {

      public var rawValue: UInt16

      public var isResponse: Bool {
        get { (rawValue & 0x8000) != 0 }
        set {
          if newValue { rawValue |= 0x8000 } else { rawValue &= ~0x8000 }
        }
      }

      public struct OpCode: RawRepresentable, Hashable, Sendable, CustomDebugStringConvertible {

        public var rawValue: UInt8

        public var debugDescription: String {
          switch self {
          case .query: return "Query"
          case .inverseQuery: return "Inverse Query"
          case .status: return "Status"
          case .notify: return "Notify"
          case .update: return "Update"
          case .dso: return "DNS Stateful Operations (DSO)"
          default: return "RAW(\(rawValue))"
          }
        }

        public init(rawValue: UInt8) {
          self.rawValue = rawValue
        }

        public static let query = OpCode(rawValue: 0)

        public static let inverseQuery = OpCode(rawValue: 1)

        public static let status = OpCode(rawValue: 2)

        public static let notify = OpCode(rawValue: 4)

        public static let update = OpCode(rawValue: 5)

        /// DNS stateful operations.
        public static let dso = OpCode(rawValue: 6)
      }

      public var opcode: OpCode {
        get { OpCode(rawValue: UInt8((rawValue & 0x7800) >> 11)) }
        set {
          rawValue = (rawValue & ~0x7800) | ((UInt16(newValue.rawValue) << 11) & 0x7800)
        }
      }

      public var isAuthoritative: Bool {
        get { (rawValue & 0x0400) != 0 }
        set { if newValue { rawValue |= 0x0400 } else { rawValue &= ~0x0400 } }
      }

      public var isTruncated: Bool {
        get { (rawValue & 0x0200) != 0 }
        set { if newValue { rawValue |= 0x0200 } else { rawValue &= ~0x0200 } }
      }

      public var recursionDesired: Bool {
        get { (rawValue & 0x0100) != 0 }
        set { if newValue { rawValue |= 0x0100 } else { rawValue &= ~0x0100 } }
      }

      public var recursionAvailable: Bool {
        get { (rawValue & 0x0080) != 0 }
        set { if newValue { rawValue |= 0x0080 } else { rawValue &= ~0x0080 } }
      }

      public var authenticatedData: Bool {
        get { (rawValue & 0x0020) != 0 }
        set { if newValue { rawValue |= 0x0020 } else { rawValue &= ~0x0020 } }
      }

      public var checkingDisabled: Bool {
        get { (rawValue & 0x0010) != 0 }
        set { if newValue { rawValue |= 0x0010 } else { rawValue &= ~0x0010 } }
      }

      public struct RCode: RawRepresentable, Hashable, Sendable, CustomDebugStringConvertible {

        public var rawValue: UInt8

        public var debugDescription: String {
          switch self {
          case .noError: return "No Error"
          case .formErr: return "Format Error"
          case .servFail: return "Server Failure"
          case .refused: return "Query Refused"
          case .notAuth: return "Not Authorized"
          case .notZone: return "Name not contained in zone"
          default: return "RAW(\(rawValue))"
          }
        }

        public init(rawValue: UInt8) {
          self.rawValue = rawValue
        }

        public static let noError = RCode(rawValue: 0)

        public static let formErr = RCode(rawValue: 1)

        public static let servFail = RCode(rawValue: 2)

        public static let notImp = RCode(rawValue: 4)

        public static let refused = RCode(rawValue: 5)

        public static let notAuth = RCode(rawValue: 9)

        public static let notZone = RCode(rawValue: 10)
      }

      public var responseCode: RCode {
        get { RCode(rawValue: UInt8(rawValue & 0x000F)) }
        set { rawValue = (rawValue & 0xFFF0) | (UInt16(newValue.rawValue) & 0x000F) }
      }

      public init(rawValue: UInt16) {
        self.rawValue = rawValue
      }

      public init(
        response: Bool,
        opcode: OpCode,
        authoritative: Bool,
        truncated: Bool,
        recursionDesired: Bool,
        recursionAvailable: Bool,
        authenticatedData: Bool,
        checkingDisabled: Bool,
        responseCode: RCode
      ) {
        self.init(rawValue: 0)
        self.isResponse = response
        self.opcode = opcode
        self.isAuthoritative = authoritative
        self.isTruncated = truncated
        self.recursionDesired = recursionDesired
        self.recursionAvailable = recursionAvailable
        self.authenticatedData = authenticatedData
        self.checkingDisabled = checkingDisabled
        self.responseCode = responseCode
      }

      public var customMirror: Mirror {
        Mirror(
          self,
          children: [
            "QR": isResponse,
            "Opcode": opcode,
            "AA (Authoritative)": isAuthoritative,
            "TC (Truncated)": isTruncated,
            "RD (Recursion Desired)": recursionDesired,
            "RA (Recursion Available)": recursionAvailable,
            "AD (Authenticated Data)": authenticatedData,
            "CD (Checking Disabled)": checkingDisabled,
            "RCODE (Response Code)": responseCode,
          ],
          displayStyle: .struct,
          ancestorRepresentation: .suppressed
        )
      }
    }

    public var transactionID: UInt16

    public var flags: Flags

    public var qestionCount: UInt16

    public var answerCount: UInt16

    public var authorityCount: UInt16

    public var additionCount: UInt16

    public init(
      transactionID: UInt16,
      flags: Flags,
      qestionCount: UInt16,
      answerCount: UInt16,
      authorityCount: UInt16,
      additionCount: UInt16
    ) {
      self.transactionID = transactionID
      self.flags = flags
      self.qestionCount = qestionCount
      self.answerCount = answerCount
      self.authorityCount = authorityCount
      self.additionCount = additionCount
    }
  }

  public var headerFields: HeaderFields

  public var questions: [Question]

  public var answerRRs: [any ResourceRecord]

  public var authorityRRs: [any ResourceRecord]

  public var additionalRRs: [any ResourceRecord]

  public init(
    headerFields: HeaderFields,
    questions: [Question],
    answerRRs: [any ResourceRecord],
    authorityRRs: [any ResourceRecord],
    additionalRRs: [any ResourceRecord]
  ) {
    self.headerFields = headerFields
    precondition(headerFields.qestionCount == questions.count)
    precondition(headerFields.answerCount == answerRRs.count)
    precondition(headerFields.authorityCount == authorityRRs.count)
    precondition(headerFields.additionCount == additionalRRs.count)

    self.questions = questions
    self.answerRRs = answerRRs
    self.authorityRRs = authorityRRs
    self.additionalRRs = additionalRRs
  }
}
