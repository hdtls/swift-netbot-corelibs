//
// See LICENSE.txt for license information
//

import AsyncDNSResolver
import CAsyncDNSResolver
import NEAddressProcessing

/// A protocol that covers an object that does DNS lookups.
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol Resolver {

  /// Lookup A records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``ARecord``s for the given name, empty if no records were found.
  func queryA(name: String) async throws -> [ARecord]

  /// Lookup AAAA records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``AAAARecord``s for the given name, empty if no records were found.
  func queryAAAA(name: String) async throws -> [AAAARecord]

  /// Lookup NS record associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``NSRecord`` for the given name.
  func queryNS(name: String) async throws -> [NSRecord]

  /// Lookup CNAME record associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: CNAME for the given name, `nil` if no record was found.
  func queryCNAME(name: String) async throws -> [CNAMERecord]

  /// Lookup SOA record associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``SOARecord`` for the given name, `nil` if no record was found.
  func querySOA(name: String) async throws -> [SOARecord]

  /// Lookup PTR record associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``PTRRecord`` for the given name.
  func queryPTR(name: String) async throws -> [PTRRecord]

  /// Lookup MX records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``MXRecord``s for the given name, empty if no records were found.
  func queryMX(name: String) async throws -> [MXRecord]

  /// Lookup TXT records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``TXTRecord``s for the given name, empty if no records were found.
  func queryTXT(name: String) async throws -> [TXTRecord]

  /// Lookup SRV records associated with `name`.
  ///
  /// - Parameters:
  ///   - name: The name to resolve.
  ///
  /// - Returns: ``SRVRecord``s for the given name, empty if no records were found.
  func querySRV(name: String) async throws -> [SRVRecord]
}

public struct DNSResolver: Resolver, Sendable {

  public struct Options: Sendable {

    public struct Flags: OptionSet, Sendable {
      public let rawValue: Int32

      public init(rawValue: Int32) {
        self.rawValue = rawValue
      }

      /// Always use TCP queries (the "virtual circuit") instead of UDP queries. Normally, TCP is only used if a UDP query yields a truncated result.
      public static let USEVC = Flags(rawValue: ARES_FLAG_USEVC)
      /// Only query the first server in the list of servers to query.
      public static let PRIMARY = Flags(rawValue: ARES_FLAG_PRIMARY)
      /// If a truncated response to a UDP query is received, do not fall back to TCP; simply continue on with the truncated response.
      public static let IGNTC = Flags(rawValue: ARES_FLAG_IGNTC)
      /// Do not set the "recursion desired" bit on outgoing queries, so that the name server being contacted will not try to fetch the answer
      /// from other servers if it doesn't know the answer locally. Be aware that this library will not do the recursion for you. Recursion must be
      /// handled by the client calling this library.
      public static let NORECURSE = Flags(rawValue: ARES_FLAG_NORECURSE)
      /// Do not close communications sockets when the number of active queries drops to zero.
      public static let STAYOPEN = Flags(rawValue: ARES_FLAG_STAYOPEN)
      /// Do not use the default search domains; only query hostnames as-is or as aliases.
      public static let NOSEARCH = Flags(rawValue: ARES_FLAG_NOSEARCH)
      /// Do not honor the HOSTALIASES environment variable, which normally specifies a file of hostname translations.
      public static let NOALIASES = Flags(rawValue: ARES_FLAG_NOALIASES)
      /// Do not discard responses with the SERVFAIL, NOTIMP, or REFUSED response code or responses whose questions don't match the
      /// questions in the request. Primarily useful for writing clients which might be used to test or debug name servers.
      public static let NOCHECKRESP = Flags(rawValue: ARES_FLAG_NOCHECKRESP)
      /// Include an EDNS pseudo-resource record (RFC 2671) in generated requests.
      public static let EDNS = Flags(rawValue: ARES_FLAG_EDNS)
    }

    public static var `default`: Options {
      .init()
    }

    /// Flags controlling the behavior of the resolver.
    ///
    /// - SeeAlso: ``CAresDNSResolver/Options/Flags``
    public var flags: Flags = .init()

    /// The number of milliseconds each name server is given to respond to a query on the first try. (After the first try, the
    /// timeout algorithm becomes more complicated, but scales linearly with the value of timeout).
    public var timeoutMillis: Int32 = 3000

    /// The number of attempts the resolver will try contacting each name server before giving up.
    public var attempts: Int32 = 3

    /// The number of dots which must be present in a domain name for it to be queried for "as is" prior to querying for it
    /// with the default domain extensions appended. The value here is the default unless set otherwise by `resolv.conf`
    /// or the `RES_OPTIONS` environment variable.
    public var numberOfDots: Int32 = 1

    /// The UDP port to use for queries. The default value is 53, the standard name service port.
    public var udpPort: UInt16 = 53

    /// The TCP port to use for queries. The default value is 53, the standard name service port.
    public var tcpPort: UInt16 = 53

    /// The socket send buffer size.
    public var socketSendBufferSize: Int32?

    /// The socket receive buffer size.
    public var socketReceiveBufferSize: Int32?

    /// The EDNS packet size.
    public var ednsPacketSize: Int32?

    /// Configures round robin selection of nameservers.
    public var rotate: Bool?

    /// The path to use for reading the resolv.conf file. The `resolvconf_path` should be set to a path string, and
    /// will be honored on \*nix like systems. The default is `/etc/resolv.conf`.
    public var resolvConfPath: String?

    /// The path to use for reading the hosts file. The `hosts_path` should be set to a path string, and
    /// will be honored on \*nix like systems. The default is `/etc/hosts`.
    public var hostsFilePath: String?

    /// The lookups to perform for host queries. `lookups` should be set to a string of the characters "b" or "f",
    /// where "b" indicates a DNS lookup and "f" indicates a lookup in the hosts file.
    public var lookups: String?

    /// The domains to search, instead of the domains specified in `resolv.conf` or the domain derived
    /// from the kernel hostname variable.
    public var domains: [String]?

    /// The list of servers to contact, instead of the servers specified in `resolv.conf` or the local named.
    ///
    /// String format is `host[:port]`. IPv6 addresses with ports require square brackets. e.g. `[2001:4860:4860::8888]:53`.
    public var servers: [String]?

    /// The address sortlist configuration, so that addresses returned by `ares_gethostbyname` are sorted
    /// according to it.
    ///
    /// String format IP-address-netmask pairs. The netmask is optional but follows the address after a slash if present.
    /// e.g., `130.155.160.0/255.255.240.0 130.155.0.0`.
    public var sortlist: [String]?
  }

  private let underlying: AsyncDNSResolver

  /// Create a dnssd DNS resolver.
  public init() throws {
    underlying = try .init()
  }

  /// Create an CAres DNS resolver with options.
  public init(options: Options) throws {
    var opts = CAresDNSResolver.Options.default
    opts.flags = .init(rawValue: options.flags.rawValue)
    opts.timeoutMillis = options.timeoutMillis
    opts.attempts = options.attempts
    opts.numberOfDots = options.numberOfDots
    opts.udpPort = options.udpPort
    opts.tcpPort = options.tcpPort
    opts.socketSendBufferSize = options.socketSendBufferSize
    opts.socketReceiveBufferSize = options.socketReceiveBufferSize
    opts.ednsPacketSize = options.ednsPacketSize
    opts.rotate = options.rotate
    opts.resolvConfPath = options.resolvConfPath
    opts.hostsFilePath = options.hostsFilePath
    opts.lookups = options.lookups
    opts.domains = options.domains
    opts.servers = options.servers
    opts.sortlist = options.sortlist
    underlying = try .init(options: opts)
  }

  public func queryA(name: String) async throws -> [ARecord] {
    try await underlying.queryA(name: name).compactMap {
      guard let data = IPv4Address($0.address.address) else {
        return nil
      }
      return ARecord(domainName: name, ttl: $0.ttl ?? 0, dataLength: .determined(4), data: data)
    }
  }

  public func queryAAAA(name: String) async throws -> [AAAARecord] {
    try await underlying.queryAAAA(name: name).compactMap {
      guard let data = IPv6Address($0.address.address) else {
        return nil
      }
      return AAAARecord(domainName: name, ttl: $0.ttl ?? 0, dataLength: .determined(16), data: data)
    }
  }

  public func queryNS(name: String) async throws -> [NSRecord] {
    try await underlying.queryNS(name: name).nameservers.map {
      NSRecord(domainName: name, ttl: 0, data: $0)
    }
  }

  public func queryCNAME(name: String) async throws -> [CNAMERecord] {
    guard let cname = try await underlying.queryCNAME(name: name) else {
      return []
    }
    return [CNAMERecord(domainName: name, ttl: 0, data: cname)]
  }

  public func querySOA(name: String) async throws -> [SOARecord] {
    try await underlying.querySOA(name: name).map {
      [
        SOARecord(
          domainName: name, ttl: Int32($0.ttl),
          data: .init(
            primaryNameServer: $0.mname ?? "", responsibleMailbox: $0.rname ?? "",
            serialNumber: $0.serial, refreshInterval: $0.refresh, retryInterval: $0.retry,
            expirationTime: $0.expire, ttl: $0.ttl))
      ]
    } ?? []
  }

  public func queryPTR(name: String) async throws -> [PTRRecord] {
    try await underlying.queryPTR(name: name).names.map {
      PTRRecord(domainName: name, ttl: 0, data: $0)
    }
  }

  public func queryMX(name: String) async throws -> [MXRecord] {
    try await underlying.queryMX(name: name).map {
      MXRecord(
        domainName: name,
        ttl: 0,
        data: .init(preference: $0.priority, exchange: $0.host)
      )
    }
  }

  public func queryTXT(name: String) async throws -> [TXTRecord] {
    try await underlying.queryTXT(name: name).map {
      TXTRecord(domainName: name, ttl: 0, data: $0.txt)
    }
  }

  public func querySRV(name: String) async throws -> [SRVRecord] {
    try await underlying.querySRV(name: name).map {
      SRVRecord(
        domainName: name,
        ttl: 0,
        data: .init(priority: $0.priority, weight: $0.weight, port: $0.port, hostname: $0.host)
      )
    }
  }
}

#if compiler(>=6.0)
  extension AsyncDNSResolver: @retroactive @unchecked Sendable {}
#else
  extension AsyncDNSResolver: @unchecked Sendable {}
#endif
