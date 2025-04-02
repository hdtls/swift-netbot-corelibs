//
// See LICENSE.txt for license information
//

public import NEAddressProcessing

public struct QueryType: RawRepresentable, Hashable, Sendable {

  public var rawValue: UInt16

  public init(rawValue: UInt16) {
    self.rawValue = rawValue
  }
}

extension QueryType {

  /// A host address.
  public static let a = QueryType(rawValue: 1)

  /// An authoritative name server.
  public static let ns = QueryType(rawValue: 2)

  public static let md = QueryType(rawValue: 3)

  public static let mf = QueryType(rawValue: 4)

  /// The canonical name for an alias.
  public static let cname = QueryType(rawValue: 5)

  /// Marks the start of a zone of authority.
  public static let soa = QueryType(rawValue: 6)

  public static let mb = QueryType(rawValue: 7)

  public static let mg = QueryType(rawValue: 8)

  public static let mr = QueryType(rawValue: 9)

  public static let null = QueryType(rawValue: 10)

  public static let wks = QueryType(rawValue: 11)

  /// A domain name pointer.
  public static let ptr = QueryType(rawValue: 12)

  public static let hinfo = QueryType(rawValue: 13)

  public static let minfo = QueryType(rawValue: 14)

  /// Mail exchange.
  public static let mx = QueryType(rawValue: 15)

  /// Text strings.
  public static let txt = QueryType(rawValue: 16)

  public static let aaaa = QueryType(rawValue: 28)

  public static let srv = QueryType(rawValue: 33)

  public static let naptr = QueryType(rawValue: 35)

  public static let axfr = QueryType(rawValue: 252)

  public static let mailb = QueryType(rawValue: 253)

  public static let maila = QueryType(rawValue: 254)

  public static let any = QueryType(rawValue: 255)
}

public struct QueryClass: RawRepresentable, Hashable, Sendable {

  public var rawValue: UInt16

  public init(rawValue: UInt16) {
    self.rawValue = rawValue
  }
}

extension QueryClass {

  public static let internet: QueryClass = QueryClass(rawValue: 1)

  public static let csnet = QueryClass(rawValue: 2)

  public static let chaos = QueryClass(rawValue: 3)

  public static let hesiod = QueryClass(rawValue: 4)

  public static let any = QueryClass(rawValue: 255)
}

/// Resource record defines information about a dns resource record,
/// including pertains domain name, type, class, ttl, data length and
/// data.
public protocol RecordProtocol: Sendable {

  associatedtype Data

  /// A domain name to which this resource record pertains.
  var ownerName: String { get }

  /// The meaning of the data in the `RDATA` field.
  var recordType: QueryType { get }

  /// The class of the data in the `RDATA` field.
  var recordClass: QueryClass { get }

  /// The time interval (in seconds) that the resource record may be
  /// cached before it should be discarded.  Zero values are
  /// interpreted to mean that the RR can only be used for the
  /// transaction in progress, and should not be cached.
  var ttl: Int32 { get }

  /// The length in octets of the `RDATA` field.
  var dataLength: UInt16 { get }

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
public struct ARecord: RecordProtocol {

  public typealias Data = IPv4Address

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 { 4 }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
    self.data = data
  }
}

/// NS record that specifies which servers are authoritative for a particular
/// domain. In simpler terms, it tells the internet where to look for the DNS
/// records for that domain.
public struct NSRecord: RecordProtocol {

  public typealias Data = String

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 {
    // 2 means 1 byte for first label length and 1 byte
    // for terminator 0.
    UInt16(data.utf8.count + 2)
  }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
    self.data = data
  }
}

/// A CNAME (Canonical Name) record is a type of DNS record used to
/// domain name to another.
///
/// Essentially, it allows you to point one domain (or subdomain) to another
/// domain, rather than directly mapping it to an IP address like with an A
/// record.
public struct CNAMERecord: RecordProtocol {

  public typealias Data = String

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 {
    UInt16(data.utf8.count + 2)
  }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
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
public struct SOARecord: RecordProtocol {

  /// `SOARecord.Data` defines authoritative information about a
  /// domain, including primary name server, administrator email, and
  /// domain settings like serial number and refresh intervals.
  public struct Data: Sendable {

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

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 {
    UInt16(
      MemoryLayout<UInt32>.size * 5 + data.primaryNameServer.utf8.count + 2
        + data.responsibleMailbox.utf8.count + 2
    )
  }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
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
public struct PTRRecord: RecordProtocol {

  public typealias Data = String

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 {
    UInt16(data.utf8.count + 2)
  }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
    self.data = data
  }
}

/// An MX (Mail Exchange) record is a type of DNS record that specifies the
/// mail servers responsible for receiving email on behalf of a domain.
///
/// When someone sends an email to an address (e.g., user@example.com),
/// the MX record tells the sending email server where to deliver the email.
public struct MXRecord: RecordProtocol {

  /// `MXRecord.Data` define mail servers responsible for handling email
  /// for a domain. It includes a priority value to determine the order in which
  /// mail servers should be used.
  public struct Data: Sendable {

    /// The priority of the mail server (lower values are preferred).
    public var preference: UInt16

    /// The mail server hostname.
    public var exchange: String

    public init(preference: UInt16, exchange: String) {
      self.preference = preference
      self.exchange = exchange
    }
  }

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 {
    UInt16(MemoryLayout<UInt16>.size + data.exchange.utf8.count + 2)
  }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
    self.data = data
  }
}

/// A TXT (Text) record is a type of DNS record that allows you to store
/// arbitrary text data in a domain's DNS zone.
///
/// While TXT records were originally designed for human-readable
/// information, they are now commonly used for a variety of purposes
/// related to domain verification and security.
public struct TXTRecord: RecordProtocol {

  public typealias Data = String

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 {
    // Different from domain name there is no terminator
    // at end just + 1 byte.
    UInt16(data.utf8.count + 1)
  }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
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
public struct AAAARecord: RecordProtocol {

  public typealias Data = IPv6Address

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 { 16 }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
    self.data = data
  }
}

/// An SRV (Service) record is a type of DNS record used to define the
/// location (hostname and port) of servers for specific services. It
/// allows you to specify the server that provides a particular service
/// (e.g., SIP, XMPP, LDAP) and is commonly used for services like instant
/// messaging, VoIP, and other network protocols that require server
/// discovery.
public struct SRVRecord: RecordProtocol {

  public struct Data: Sendable {

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

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 {
    UInt16(MemoryLayout<UInt16>.size * 3 + data.hostname.utf8.count + 2)
  }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
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
public struct NAPTRRecord: RecordProtocol {

  public struct Data: Sendable {

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

  public var ownerName: String

  public var recordType: QueryType

  public var recordClass: QueryClass

  public var ttl: Int32

  public var dataLength: UInt16 {
    UInt16(
      MemoryLayout<UInt16>.size * 2 + data.flags.utf8.count + 1 + data.services.utf8.count + 1
        + data.regExp
        .utf8.count + 1 + data.replacement.utf8.count + 2
    )
  }

  public var data: Data

  public init(
    ownerName: String,
    recordType: QueryType,
    recordClass: QueryClass,
    ttl: Int32,
    data: Data
  ) {
    self.ownerName = ownerName
    self.recordType = recordType
    self.recordClass = recordClass
    self.ttl = ttl
    self.data = data
  }
}

/// The question is used to carry the "question" in most DNS queries.
public struct Question: Hashable, Sendable {

  /// The domain name to query.
  public var domainName: String

  /// The type of the dns query.
  public var queryType: QueryType

  /// The type of the dns query.
  public var queryClass: QueryClass

  public init(domainName: String, queryType: QueryType, queryClass: QueryClass) {
    self.domainName = domainName
    self.queryType = queryType
    self.queryClass = queryClass
  }
}

public struct Message: Sendable {

  public struct HeaderFields: Hashable, Sendable {

    public struct Flags: CustomReflectable, Hashable, RawRepresentable, Sendable {

      public var rawValue: UInt16

      public var isResponse: Bool {
        get { (rawValue & 0x8000) != 0 }
        set {
          if newValue { rawValue |= 0x8000 } else { rawValue &= ~0x8000 }
        }
      }

      public var opcode: UInt8 {
        get { UInt8((rawValue & 0x7800) >> 11) }
        set {
          rawValue = (rawValue & ~0x7800) | ((UInt16(newValue) << 11) & 0x7800)
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

      public var responseCode: UInt8 {
        get { UInt8(rawValue & 0x000F) }
        set { rawValue = (rawValue & 0xFFF0) | (UInt16(newValue) & 0x000F) }
      }

      public init(rawValue: UInt16) {
        self.rawValue = rawValue
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

  public var answerRRs: [any RecordProtocol]

  public var authorityRRs: [any RecordProtocol]

  public var additionalRRs: [any RecordProtocol]

  public init(
    headerFields: HeaderFields,
    questions: [Question],
    answerRRs: [any RecordProtocol],
    authorityRRs: [any RecordProtocol],
    additionalRRs: [any RecordProtocol]
  ) {
    self.headerFields = headerFields
    self.questions = questions
    self.answerRRs = answerRRs
    self.authorityRRs = authorityRRs
    self.additionalRRs = additionalRRs
  }
}
